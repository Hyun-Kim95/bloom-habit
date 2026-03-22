import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, In } from 'typeorm';
import cron from 'node-cron';

import { Habit, HabitRecord, Inquiry, MissedHabitPushLog, User } from '../entities';

function retentionDays(): number {
  const raw = process.env.INACTIVE_USER_RETENTION_DAYS;
  if (raw == null || raw.trim() === '') return 365;
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) && n >= 1 ? n : 365;
}

@Injectable()
export class InactiveUserPurgeScheduler {
  private static _scheduled = false;

  constructor(@InjectDataSource() private readonly dataSource: DataSource) {
    this.start();
  }

  private start(): void {
    if (InactiveUserPurgeScheduler._scheduled) return;
    InactiveUserPurgeScheduler._scheduled = true;

    const cronExpr =
      process.env.INACTIVE_USER_PURGE_CRON_OVERRIDE || '0 4 * * *';

    cron.schedule(cronExpr, async () => {
      try {
        await this.runOnce();
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('[InactiveUserPurge] cron run failed', e);
      }
    });

    if (process.env.INACTIVE_USER_PURGE_RUN_ON_START === 'true') {
      this.runOnce().catch((e) => {
        // eslint-disable-next-line no-console
        console.error('[InactiveUserPurge] run on start failed', e);
      });
    }
  }

  /**
   * 비활성화된 지 retentionDays 이상 지난 사용자: 습관·기록·푸시 로그·문의·user 행 삭제.
   */
  async runOnce(): Promise<{ purgedUsers: number }> {
    const days = retentionDays();
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    // eslint-disable-next-line no-console
    console.log(
      `[InactiveUserPurge] runOnce start (retentionDays=${days}, cutoff=${cutoff.toISOString()})`,
    );

    const result = await this.dataSource.transaction(async (em) => {
      const users = await em
        .createQueryBuilder(User, 'u')
        .select(['u.id'])
        .where('u.isActive = :active', { active: false })
        .andWhere('u.deactivatedAt IS NOT NULL')
        .andWhere('u.deactivatedAt < :cutoff', { cutoff })
        .getMany();

      if (users.length === 0) {
        return { purgedUsers: 0 };
      }

      for (const user of users) {
        const habits = await em.find(Habit, {
          where: { userId: user.id },
          select: ['id'],
        });
        const habitIds = habits.map((h) => h.id);
        if (habitIds.length > 0) {
          await em.delete(HabitRecord, { habitId: In(habitIds) });
        }
        await em.delete(Habit, { userId: user.id });
        await em.delete(MissedHabitPushLog, { userId: user.id });
        await em.delete(Inquiry, { userId: user.id });
        await em.delete(User, { id: user.id });
      }

      return { purgedUsers: users.length };
    });

    // eslint-disable-next-line no-console
    console.log(`[InactiveUserPurge] runOnce done. purgedUsers=${result.purgedUsers}`);

    return result;
  }
}
