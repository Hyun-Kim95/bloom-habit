import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Habit as HabitEntity, HabitRecord as HabitRecordEntity } from '../entities';

export interface HabitDto {
  id: string;
  userId: string;
  name: string;
  category?: string;
  goalType: string;
  goalValue?: number;
  startDate: string;
  colorHex?: string;
  iconName?: string;
  archivedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface RecordDto {
  id: string;
  habitId: string;
  recordDate: string;
  value?: number;
  completed: boolean;
  createdAt: string;
  updatedAt: string;
}

function toHabitDto(e: HabitEntity): HabitDto {
  return {
    id: e.id,
    userId: e.userId,
    name: e.name,
    category: e.category ?? undefined,
    goalType: e.goalType,
    goalValue: e.goalValue ?? undefined,
    startDate: e.startDate,
    colorHex: e.colorHex ?? undefined,
    iconName: e.iconName ?? undefined,
    archivedAt: e.archivedAt ? e.archivedAt.toISOString() : undefined,
    createdAt: e.createdAt.toISOString(),
    updatedAt: e.updatedAt.toISOString(),
  };
}

function toRecordDto(e: HabitRecordEntity): RecordDto {
  return {
    id: e.id,
    habitId: e.habitId,
    recordDate: e.recordDate,
    value: e.value ?? undefined,
    completed: e.completed,
    createdAt: e.createdAt.toISOString(),
    updatedAt: e.updatedAt.toISOString(),
  };
}

@Injectable()
export class HabitsService {
  constructor(
    @InjectRepository(HabitEntity)
    private readonly habitRepo: Repository<HabitEntity>,
    @InjectRepository(HabitRecordEntity)
    private readonly recordRepo: Repository<HabitRecordEntity>,
  ) {}

  async list(userId: string, archived = false): Promise<HabitDto[]> {
    const qb = this.habitRepo
      .createQueryBuilder('h')
      .where('h.userId = :userId', { userId })
      .orderBy('h.createdAt', 'ASC');
    if (archived) {
      qb.andWhere('h.archivedAt IS NOT NULL');
    } else {
      qb.andWhere('h.archivedAt IS NULL');
    }
    const list = await qb.getMany();
    return list.map(toHabitDto);
  }

  async get(id: string, userId: string): Promise<HabitDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id, userId } });
    return h ? toHabitDto(h) : undefined;
  }

  async create(
    userId: string,
    body: {
      name: string;
      category?: string;
      goalType: string;
      goalValue?: number;
      startDate: string;
      colorHex?: string;
      iconName?: string;
    },
  ): Promise<HabitDto> {
    const habit = this.habitRepo.create({
      id: `h-${uuidv4()}`,
      userId,
      name: body.name,
      category: body.category,
      goalType: body.goalType ?? 'completion',
      goalValue: body.goalValue,
      startDate: body.startDate,
      colorHex: body.colorHex,
      iconName: body.iconName,
      archivedAt: null,
    });
    await this.habitRepo.save(habit);
    return toHabitDto(habit);
  }

  async update(
    id: string,
    userId: string,
    body: Partial<Pick<HabitDto, 'name' | 'category' | 'goalType' | 'goalValue' | 'colorHex' | 'iconName'>>,
  ): Promise<HabitDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id, userId } });
    if (!h) return undefined;
    Object.assign(h, body);
    await this.habitRepo.save(h);
    return toHabitDto(h);
  }

  async delete(id: string, userId: string): Promise<boolean> {
    const h = await this.habitRepo.findOne({ where: { id, userId } });
    if (!h) return false;
    await this.recordRepo.delete({ habitId: id });
    await this.habitRepo.remove(h);
    return true;
  }

  async archive(id: string, userId: string): Promise<HabitDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id, userId } });
    if (!h) return undefined;
    h.archivedAt = new Date();
    await this.habitRepo.save(h);
    return toHabitDto(h);
  }

  async getRecord(recordId: string, userId: string): Promise<RecordDto | undefined> {
    const r = await this.recordRepo.findOne({ where: { id: recordId } });
    if (!r) return undefined;
    const h = await this.habitRepo.findOne({ where: { id: r.habitId, userId } });
    return h ? toRecordDto(r) : undefined;
  }

  async listRecords(habitId: string, userId: string, from?: string, to?: string): Promise<RecordDto[]> {
    const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
    if (!h) return [];
    const qb = this.recordRepo
      .createQueryBuilder('r')
      .where('r.habitId = :habitId', { habitId })
      .orderBy('r.recordDate', 'ASC');
    if (from) qb.andWhere('r.recordDate >= :from', { from });
    if (to) qb.andWhere('r.recordDate <= :to', { to });
    const list = await qb.getMany();
    return list.map(toRecordDto);
  }

  async addRecord(
    habitId: string,
    userId: string,
    body: { recordDate: string; value?: number; completed: boolean },
  ): Promise<RecordDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
    if (!h) return undefined;
    const existing = await this.recordRepo.findOne({
      where: { habitId, recordDate: body.recordDate },
    });
    if (existing) {
      existing.value = body.value ?? existing.value;
      existing.completed = body.completed;
      await this.recordRepo.save(existing);
      return toRecordDto(existing);
    }
    const record = this.recordRepo.create({
      id: `r-${uuidv4()}`,
      habitId,
      recordDate: body.recordDate,
      value: body.value,
      completed: body.completed,
    });
    await this.recordRepo.save(record);
    return toRecordDto(record);
  }

  async updateRecord(
    habitId: string,
    recordId: string,
    userId: string,
    body: { completed?: boolean; value?: number },
  ): Promise<RecordDto | undefined> {
    const r = await this.recordRepo.findOne({ where: { id: recordId, habitId } });
    if (!r) return undefined;
    const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
    if (!h) return undefined;
    if (body.completed !== undefined) r.completed = body.completed;
    if (body.value !== undefined) r.value = body.value;
    await this.recordRepo.save(r);
    return toRecordDto(r);
  }

  async deleteRecord(habitId: string, recordId: string, userId: string): Promise<boolean> {
    const r = await this.recordRepo.findOne({ where: { id: recordId, habitId } });
    if (!r) return false;
    const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
    if (!h) return false;
    await this.recordRepo.remove(r);
    return true;
  }

  async getSyncPayload(userId: string, _since?: string): Promise<{ habits: HabitDto[]; records: RecordDto[] }> {
    const habitList = await this.list(userId, true);
    const habitIds = habitList.map((h) => h.id);
    if (habitIds.length === 0) {
      return { habits: habitList, records: [] };
    }
    const recordList = await this.recordRepo
      .createQueryBuilder('r')
      .where('r.habitId IN (:...ids)', { ids: habitIds })
      .orderBy('r.recordDate', 'ASC')
      .getMany();
    return { habits: habitList, records: recordList.map(toRecordDto) };
  }

  /** 최근 7일 완료 기록 수 (레벨 산정용) */
  async getCompletedCountLast7Days(userId: string): Promise<number> {
    const habits = await this.habitRepo
      .createQueryBuilder('h')
      .select('h.id')
      .where('h.userId = :userId', { userId })
      .andWhere('h.archivedAt IS NULL')
      .getMany();
    const habitIds = habits.map((h) => h.id);
    if (habitIds.length === 0) return 0;
    const from = new Date();
    from.setDate(from.getDate() - 6);
    const fromStr = from.toISOString().slice(0, 10);
    const toStr = new Date().toISOString().slice(0, 10);
    const count = await this.recordRepo
      .createQueryBuilder('r')
      .where('r.habitId IN (:...ids)', { ids: habitIds })
      .andWhere('r.recordDate >= :from', { from: fromStr })
      .andWhere('r.recordDate <= :to', { to: toStr })
      .andWhere('r.completed = :completed', { completed: true })
      .getCount();
    return count;
  }

  /** 관리자용: 전체 습관/기록 수 */
  async getTotalCounts(): Promise<{ totalHabits: number; totalRecords: number }> {
    const [totalHabits, totalRecords] = await Promise.all([
      this.habitRepo.count(),
      this.recordRepo.count(),
    ]);
    return { totalHabits, totalRecords };
  }

  /** 관리자용: 회원별 습관 수·기록 수·완료 수 (한 번에 조회) */
  async getUserStatsMap(
    userIds: string[],
  ): Promise<
    Record<string, { habitCount: number; totalRecords: number; completedRecords: number }>
  > {
    if (userIds.length === 0) return {};
    const habitCounts = await this.habitRepo
      .createQueryBuilder('h')
      .select('h.userId', 'userId')
      .addSelect('COUNT(*)', 'cnt')
      .where('h.userId IN (:...ids)', { ids: userIds })
      .andWhere('h.archivedAt IS NULL')
      .groupBy('h.userId')
      .getRawMany<{ userId: string; cnt: string }>();
    const habitIdsByUser = await this.habitRepo
      .createQueryBuilder('h')
      .select('h.id', 'id')
      .addSelect('h.userId', 'userId')
      .where('h.userId IN (:...ids)', { ids: userIds })
      .andWhere('h.archivedAt IS NULL')
      .getRawMany<{ id: string; userId: string }>();
    const allHabitIds = habitIdsByUser.map((r) => r.id);
    let recordCounts: { habitId: string; total: string; completed: string }[] = [];
    if (allHabitIds.length > 0) {
      recordCounts = await this.recordRepo
        .createQueryBuilder('r')
        .select('r.habitId', 'habitId')
        .addSelect('COUNT(*)', 'total')
        .addSelect('SUM(CASE WHEN r.completed = true THEN 1 ELSE 0 END)', 'completed')
        .where('r.habitId IN (:...ids)', { ids: allHabitIds })
        .groupBy('r.habitId')
        .getRawMany();
    }
    const userToHabits = new Map<string, string[]>();
    for (const r of habitIdsByUser) {
      if (!userToHabits.has(r.userId)) userToHabits.set(r.userId, []);
      userToHabits.get(r.userId)!.push(r.id);
    }
    const recordByHabit = new Map(
      recordCounts.map((r) => [r.habitId, { total: parseInt(r.total, 10), completed: parseInt(r.completed, 10) }]),
    );
    const result: Record<string, { habitCount: number; totalRecords: number; completedRecords: number }> = {};
    for (const uid of userIds) {
      const habitCount = habitCounts.find((c) => c.userId === uid);
      const count = habitCount ? parseInt(habitCount.cnt, 10) : 0;
      const habitIds = userToHabits.get(uid) ?? [];
      let totalRecords = 0;
      let completedRecords = 0;
      for (const hid of habitIds) {
        const rec = recordByHabit.get(hid);
        if (rec) {
          totalRecords += rec.total;
          completedRecords += rec.completed;
        }
      }
      result[uid] = { habitCount: count, totalRecords, completedRecords };
    }
    return result;
  }
}
