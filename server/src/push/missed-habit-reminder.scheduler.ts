import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import cron from 'node-cron';

import { Habit, HabitRecord, MissedHabitPushLog, User } from '../entities';
import { PushService } from './push.service';

function toYmdLocal(d: Date) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

@Injectable()
export class MissedHabitReminderScheduler {
  private static _scheduled = false;

  constructor(
    private readonly pushService: PushService,
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

    // 매일 23:00 (서버 = PC 기준 시간). 테스트 시 MISSED_HABIT_CRON_OVERRIDE 로 변경 가능 (예: "*/2 * * * *" = 2분마다)
    const cronExpr = process.env.MISSED_HABIT_CRON_OVERRIDE || '0 23 * * *';
    cron.schedule(cronExpr, async () => {
      try {
        await this.runOnce({ force: false });
      } catch {
        // 알림 실패는 조용히 무시(재시도 로직은 추후 확장)
      }
    });

    // 개발/테스트 편의: 서버 시작 시 한 번 즉시 실행
    if (process.env.MISSED_HABIT_RUN_ON_START === 'true') {
      this.runOnce({ force: true }).catch(() => {});
    }
  }

  async runOnce({ force = false }: { force?: boolean } = {}): Promise<void> {
    const todayStr = toYmdLocal(new Date());
    // eslint-disable-next-line no-console
    console.log(`[MissedHabitReminder] runOnce start (today=${todayStr}, force=${force})`);

    // 오늘 완료된 habitId 집합
    const completed = await this.habitRecordRepo.find({
      where: { recordDate: todayStr, completed: true },
      select: ['habitId'],
    });
    const completedHabitIds = new Set(completed.map((r) => r.habitId));

    // 활성 습관 중, 오늘 시작 전/후 필터(간단 문자열 비교: YYYY-MM-DD)
    // TypeORM where null 타입 이슈를 피하기 위해 쿼리빌더 사용
    const habits = await this.habitRepo
      .createQueryBuilder('h')
      .innerJoin(User, 'u', 'u.id = h.userId AND u.isActive = true')
      .where('h.archivedAt IS NULL')
      .getMany();

    const missedByUserId = new Map<string, string[]>();
    for (const h of habits) {
      if (h.startDate && h.startDate > todayStr) continue;
      if (completedHabitIds.has(h.id)) continue;
      const arr = missedByUserId.get(h.userId) ?? [];
      arr.push(h.name);
      missedByUserId.set(h.userId, arr);
    }

    if (missedByUserId.size === 0) {
      // eslint-disable-next-line no-console
      console.log('[MissedHabitReminder] no missed habits. skip.');
      return;
    }

    // eslint-disable-next-line no-console
    console.log(
      `[MissedHabitReminder] missedByUserId=${missedByUserId.size}`,
    );

    const userIds = [...missedByUserId.keys()];
    const users = await this.userRepo.find({
      where: { id: In(userIds), isActive: true },
      select: ['id', 'fcmToken', 'isActive'],
    });
    // eslint-disable-next-line no-console
    console.log(
      `[MissedHabitReminder] userIds=${userIds.length} usersFetched=${users.length}`,
    );

    const usersWithToken = users.filter((u) => u.fcmToken?.trim());
    // eslint-disable-next-line no-console
    console.log(
      `[MissedHabitReminder] usersWithToken=${usersWithToken.length}`,
    );

    // 오늘 이미 보냈던 사용자 스킵
    const logs = await this.logRepo.find({
      where: { pushDate: todayStr, userId: In(userIds) },
      select: ['userId'],
    });
    const alreadySent = new Set(logs.map((l) => l.userId));
    // eslint-disable-next-line no-console
    console.log(`[MissedHabitReminder] alreadySent=${alreadySent.size}`);

    let sent = 0;
    const sentTokens = new Set<string>();

    for (const user of users) {
      const token = user.fcmToken?.trim();
      if (!token) continue;
      if (!force && alreadySent.has(user.id)) continue;
      if (sentTokens.has(token)) continue;
      const missedNames = missedByUserId.get(user.id) ?? [];
      if (missedNames.length === 0) continue;

      // eslint-disable-next-line no-console
      console.log(
        `[MissedHabitReminder] sending to user=${user.id} missedCount=${missedNames.length}`,
      );

      await this.pushService.sendMissedHabitReminderNotification({
        userId: user.id,
        missedHabitNames: missedNames,
      });
      sentTokens.add(token);

      if (force) {
        await this.logRepo.delete({ userId: user.id, pushDate: todayStr });
      }
      const log = this.logRepo.create({ userId: user.id, pushDate: todayStr });
      await this.logRepo.save(log);
      sent++;
    }

    // eslint-disable-next-line no-console
    console.log(`[MissedHabitReminder] runOnce done. sent=${sent}`);
  }
}

