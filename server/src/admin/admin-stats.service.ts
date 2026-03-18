import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, Habit, HabitRecord } from '../entities';

export interface StatsOverTimeItem {
  period: string; // YYYY-MM-DD (week start Monday)
  newUsers: number;
  newHabits: number;
  newRecords: number;
}

@Injectable()
export class AdminStatsService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Habit)
    private readonly habitRepo: Repository<Habit>,
    @InjectRepository(HabitRecord)
    private readonly recordRepo: Repository<HabitRecord>,
  ) {}

  async getStatsOverTime(fromStr: string, toStr: string): Promise<StatsOverTimeItem[]> {
    const from = new Date(fromStr + 'T00:00:00.000Z');
    const to = new Date(toStr + 'T23:59:59.999Z');
    const buckets = this.getWeekBuckets(from, to);
    if (buckets.length === 0) return [];

    const result: StatsOverTimeItem[] = [];
    for (const { start, end } of buckets) {
      const period = start.toISOString().slice(0, 10);
      const [newUsers, newHabits, newRecords] = await Promise.all([
        this.userRepo
          .createQueryBuilder('u')
          .where('u.createdAt >= :start', { start })
          .andWhere('u.createdAt <= :end', { end })
          .getCount(),
        this.habitRepo
          .createQueryBuilder('h')
          .where('h.createdAt >= :start', { start })
          .andWhere('h.createdAt <= :end', { end })
          .getCount(),
        this.recordRepo
          .createQueryBuilder('r')
          .where('r.createdAt >= :start', { start })
          .andWhere('r.createdAt <= :end', { end })
          .getCount(),
      ]);
      result.push({ period, newUsers, newHabits, newRecords });
    }
    return result;
  }

  private getWeekBuckets(from: Date, to: Date): { start: Date; end: Date }[] {
    const buckets: { start: Date; end: Date }[] = [];
    const cur = new Date(from);
    cur.setUTCHours(0, 0, 0, 0);
    const day = cur.getUTCDay();
    const diff = day === 0 ? 6 : day - 1;
    cur.setUTCDate(cur.getUTCDate() - diff);
    while (cur <= to) {
      const start = new Date(cur);
      const end = new Date(cur);
      end.setUTCDate(end.getUTCDate() + 6);
      end.setUTCHours(23, 59, 59, 999);
      buckets.push({ start, end });
      cur.setUTCDate(cur.getUTCDate() + 7);
    }
    return buckets;
  }
}
