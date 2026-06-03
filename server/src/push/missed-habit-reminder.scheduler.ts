import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import cron from 'node-cron';
import { DateTime } from 'luxon';

import { Habit, HabitRecord, MissedHabitPushLog, User } from '../entities';
import { isHabitMissedForReminder } from '../habits/habits-goal-completion';
import { PushService } from './push.service';

/** DB에 타임존이 없을 때 미달성 푸시·로컬일 판정에 사용 */
const DEFAULT_IANA_TZ = 'Asia/Seoul';

function effectiveIana(user: { ianaTimeZone: string | null }): string {
  const z = user.ianaTimeZone?.trim();
  if (z && DateTime.now().setZone(z).isValid) return z;
  return DEFAULT_IANA_TZ;
}

function parseDefaultSendHM(): { hour: number; minute: number } {
  const hourRaw = parseInt(process.env.MISSED_HABIT_LOCAL_SEND_HOUR ?? '23', 10);
  const minuteRaw = parseInt(process.env.MISSED_HABIT_LOCAL_SEND_MINUTE ?? '0', 10);
  const hour = Number.isFinite(hourRaw) ? Math.min(23, Math.max(0, hourRaw)) : 23;
  const minute = Number.isFinite(minuteRaw) ? Math.min(59, Math.max(0, minuteRaw)) : 0;
  return { hour, minute };
}

/** 틱 크론(기본 5분)과 겹치지 않게 하려면 전송 창이 너무 짧으면 안 됨 — env로 더 줄여도 최소 이 값. */
const MIN_SEND_WINDOW_MINUTES = 15;

function parseWindowMinutes(): number {
  const windowRaw = parseInt(process.env.MISSED_HABIT_SEND_WINDOW_MINUTES ?? '15', 10);
  const parsed = Number.isFinite(windowRaw) ? Math.min(180, Math.max(1, windowRaw)) : 15;
  return Math.max(MIN_SEND_WINDOW_MINUTES, parsed);
}

function userSendHM(
  user: {
    missedHabitPushLocalHour: number | null;
    missedHabitPushLocalMinute: number | null;
  },
  fallback: { hour: number; minute: number },
): { hour: number; minute: number } {
  if (user.missedHabitPushLocalHour != null && user.missedHabitPushLocalMinute != null) {
    return { hour: user.missedHabitPushLocalHour, minute: user.missedHabitPushLocalMinute };
  }
  return fallback;
}

function inLocalSendWindow(
  localNow: DateTime,
  hour: number,
  minute: number,
  windowMinutes: number,
): boolean {
  const start = hour * 60 + minute;
  const cur = localNow.hour * 60 + localNow.minute;
  return cur >= start && cur < start + windowMinutes;
}

@Injectable()
export class MissedHabitReminderScheduler {
  private static _scheduled = false;

  constructor(
    private readonly pushService: PushService,
    @InjectDataSource()
    private readonly dataSource: DataSource,
    @InjectRepository(Habit)
    private readonly habitRepo: Repository<Habit>,
    @InjectRepository(HabitRecord)
    private readonly habitRecordRepo: Repository<HabitRecord>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(MissedHabitPushLog)
    private readonly logRepo: Repository<MissedHabitPushLog>,
  ) {
    this.start();
  }

  private start() {
    if (MissedHabitReminderScheduler._scheduled) return;
    MissedHabitReminderScheduler._scheduled = true;

    const cronExpr = process.env.MISSED_HABIT_TICK_CRON ?? '*/5 * * * *';
    cron.schedule(cronExpr, async () => {
      try {
        await this.runOnce({ force: false });
      } catch {
        // 알림 실패는 조용히 무시(재시도는 다음 틱)
      }
    });

    if (process.env.MISSED_HABIT_RUN_ON_START === 'true') {
      this.runOnce({ force: true }).catch(() => {});
    }
  }

  async runOnce({ force = false }: { force?: boolean } = {}): Promise<void> {
    const defaultHm = parseDefaultSendHM();
    const windowMinutes = parseWindowMinutes();
    // eslint-disable-next-line no-console
    console.log(
      `[MissedHabitReminder] runOnce start (force=${force}, defaultLocal=${defaultHm.hour}:${String(defaultHm.minute).padStart(2, '0')}+${windowMinutes}m)`,
    );

    const habits = await this.habitRepo
      .createQueryBuilder('h')
      .innerJoin(User, 'u', 'u.id = h.userId AND u.isActive = true')
      .where('h.archivedAt IS NULL')
      .getMany();

    const habitsByUser = new Map<string, Habit[]>();
    for (const h of habits) {
      const arr = habitsByUser.get(h.userId) ?? [];
      arr.push(h);
      habitsByUser.set(h.userId, arr);
    }

    const users = await this.userRepo.find({
      where: { isActive: true },
      select: [
        'id',
        'fcmToken',
        'ianaTimeZone',
        'missedHabitPushLocalHour',
        'missedHabitPushLocalMinute',
        'isActive',
      ],
    });
    const usersWithToken = users.filter((u) => u.fcmToken?.trim());
    if (usersWithToken.length === 0) {
      // eslint-disable-next-line no-console
      console.log('[MissedHabitReminder] no users with FCM token. skip.');
      return;
    }

    type Candidate = { user: (typeof usersWithToken)[0]; localDate: string; iana: string };
    const candidates: Candidate[] = [];

    for (const user of usersWithToken) {
      const iana = effectiveIana(user);
      const localNow = DateTime.now().setZone(iana);
      if (!localNow.isValid) continue;

      const hm = userSendHM(user, defaultHm);
      if (!force && !inLocalSendWindow(localNow, hm.hour, hm.minute, windowMinutes)) {
        continue;
      }

      const localDate = localNow.toISODate();
      if (!localDate) continue;

      const userHabits = habitsByUser.get(user.id) ?? [];
      if (userHabits.length === 0) continue;

      candidates.push({ user, localDate, iana });
    }

    if (candidates.length === 0) {
      // eslint-disable-next-line no-console
      console.log('[MissedHabitReminder] no candidates in send window (or no habits). skip.');
      return;
    }

    const uniqueDates = [...new Set(candidates.map((c) => c.localDate))];
    const recordsByDate = new Map<
      string,
      Map<string, { value: number | null; completed: boolean }>
    >();
    for (const d of uniqueDates) {
      const rows = await this.habitRecordRepo.find({
        where: { recordDate: d },
        select: ['habitId', 'value', 'completed'],
      });
      const byHabit = new Map<string, { value: number | null; completed: boolean }>();
      for (const r of rows) {
        byHabit.set(r.habitId, { value: r.value, completed: r.completed });
      }
      recordsByDate.set(d, byHabit);
    }

    let sent = 0;
    for (const { user, localDate } of candidates) {
      const recordsByHabit = recordsByDate.get(localDate) ?? new Map();
      const userHabits = habitsByUser.get(user.id) ?? [];
      const missedNames: string[] = [];
      for (const h of userHabits) {
        if (h.startDate && h.startDate > localDate) continue;
        const record = recordsByHabit.get(h.id);
        if (!isHabitMissedForReminder(h, record)) continue;
        missedNames.push(h.name);
      }
      if (missedNames.length === 0) continue;

      if (force) {
        await this.logRepo.delete({ userId: user.id, pushDate: localDate });
      }

      const inserted = await this.tryClaimPushSlot(user.id, localDate);
      if (!inserted) {
        continue;
      }

      // eslint-disable-next-line no-console
      console.log(
        `[MissedHabitReminder] sending to user=${user.id} pushDate=${localDate} missedCount=${missedNames.length}`,
      );

      const ok = await this.pushService.sendMissedHabitReminderNotification({
        userId: user.id,
        missedHabitNames: missedNames,
      });
      if (!ok) {
        await this.logRepo.delete({ userId: user.id, pushDate: localDate });
      } else {
        sent++;
      }
    }

    // eslint-disable-next-line no-console
    console.log(`[MissedHabitReminder] runOnce done. sent=${sent}`);
  }

  /** @returns true if this invocation claimed the send slot (insert succeeded). */
  private async tryClaimPushSlot(userId: string, pushDate: string): Promise<boolean> {
    const rows: { id: number }[] = await this.dataSource.query(
      `INSERT INTO "missed_habit_push_logs" ("userId", "pushDate") VALUES ($1, $2)
       ON CONFLICT ("userId", "pushDate") DO NOTHING
       RETURNING id`,
      [userId, pushDate],
    );
    return rows.length > 0;
  }
}
