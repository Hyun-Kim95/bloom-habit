import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import {
  Habit as HabitEntity,
  HabitRecord as HabitRecordEntity,
  HabitTemplate as HabitTemplateEntity,
} from '../entities';

export interface HabitDto {
  id: string;
  userId: string;
  name: string;
  category?: string;
  goalType: string;
  numberDirection: 'gte' | 'lte';
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

export interface HabitTemplateDto {
  id: string;
  name: string;
  nameEn?: string;
  category?: string;
  categoryEn?: string;
  goalType: string;
  numberDirection: 'gte' | 'lte';
  goalValue?: number;
  colorHex?: string;
  iconName?: string;
}

function toHabitDto(e: HabitEntity): HabitDto {
  return {
    id: e.id,
    userId: e.userId,
    name: e.name,
    category: e.category ?? undefined,
    goalType: e.goalType,
    numberDirection: e.numberDirection === 'lte' ? 'lte' : 'gte',
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
    @InjectRepository(HabitTemplateEntity)
    private readonly templateRepo: Repository<HabitTemplateEntity>,
  ) {}

  async listActiveTemplates(): Promise<HabitTemplateDto[]> {
    const list = await this.templateRepo.find({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });
    return list.map((t) => ({
      id: t.id,
      name: t.name,
      nameEn: t.nameEn ?? undefined,
      category: t.category ?? undefined,
      categoryEn: t.categoryEn ?? undefined,
      goalType: t.goalType,
      numberDirection: t.numberDirection === 'lte' ? 'lte' : 'gte',
      goalValue: t.goalValue ?? undefined,
      colorHex: t.colorHex ?? undefined,
      iconName: t.iconName ?? undefined,
    }));
  }

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
      numberDirection?: 'gte' | 'lte';
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
      numberDirection: this.normalizeNumberDirection(body.numberDirection),
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
    body: Partial<Pick<HabitDto, 'name' | 'category' | 'goalType' | 'numberDirection' | 'goalValue' | 'colorHex' | 'iconName'>>,
  ): Promise<HabitDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id, userId } });
    if (!h) return undefined;
    Object.assign(h, body);
    if (body.numberDirection !== undefined) {
      h.numberDirection = this.normalizeNumberDirection(body.numberDirection);
    }
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
    h.archivedAt = h.archivedAt ? null : new Date();
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
    body: { recordDate: string; value?: number; completed?: boolean },
  ): Promise<RecordDto | undefined> {
    const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
    if (!h) return undefined;
    const existing = await this.recordRepo.findOne({
      where: { habitId, recordDate: body.recordDate },
    });
    if (existing) {
      const merged = this.mergeRecordByGoalType(h, existing.value, body.value, body.completed);
      existing.value = merged.value;
      existing.completed = merged.completed;
      await this.recordRepo.save(existing);
      return toRecordDto(existing);
    }
    const merged = this.mergeRecordByGoalType(h, null, body.value, body.completed);
    const record = this.recordRepo.create({
      id: `r-${uuidv4()}`,
      habitId,
      recordDate: body.recordDate,
      value: merged.value,
      completed: merged.completed,
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
    const next = this.updateRecordByGoalType(
      h,
      r.value,
      r.completed,
      body.value,
      body.completed,
    );
    r.value = next.value;
    r.completed = next.completed;
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
    // `list(userId, false)` = 활성, `true` = 숨김(아카이브). 둘 다 내려야 앱·다기기 동기화가 맞음.
    const [active, archived] = await Promise.all([
      this.list(userId, false),
      this.list(userId, true),
    ]);
    const habitList = [...active, ...archived];
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

  private normalizeNumberDirection(raw?: string): 'gte' | 'lte' {
    return raw === 'lte' ? 'lte' : 'gte';
  }

  private normalizeGoalType(raw?: string): 'completion' | 'count' | 'duration' | 'number' {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'count':
        return 'count';
      case 'duration':
        return 'duration';
      case 'number':
        return 'number';
      default:
        return 'completion';
    }
  }

  private mergeRecordByGoalType(
    habit: HabitEntity,
    existingValue: number | null,
    incomingValue?: number,
    incomingCompleted?: boolean,
  ): { value: number | null; completed: boolean } {
    const goalType = this.normalizeGoalType(habit.goalType);
    if (goalType === 'completion') {
      return {
        value: incomingValue ?? existingValue ?? null,
        completed: incomingCompleted ?? true,
      };
    }

    const step = Number.isFinite(Number(incomingValue)) ? Number(incomingValue) : 1;
    const prev = Number.isFinite(Number(existingValue)) ? Number(existingValue) : 0;
    const nextValue = prev + step;
    return {
      value: nextValue,
      completed: this.computeCompleted(
        goalType,
        nextValue,
        habit.goalValue,
        this.normalizeNumberDirection(habit.numberDirection),
      ),
    };
  }

  private updateRecordByGoalType(
    habit: HabitEntity,
    existingValue: number | null,
    existingCompleted: boolean,
    nextValueInput?: number,
    completedInput?: boolean,
  ): { value: number | null; completed: boolean } {
    const goalType = this.normalizeGoalType(habit.goalType);
    if (goalType === 'completion') {
      return {
        value: nextValueInput ?? existingValue ?? null,
        completed: completedInput ?? existingCompleted,
      };
    }

    const nextValue =
      nextValueInput !== undefined
        ? Number(nextValueInput)
        : Number.isFinite(Number(existingValue))
          ? Number(existingValue)
          : 0;
    return {
      value: nextValue,
      completed: this.computeCompleted(
        goalType,
        nextValue,
        habit.goalValue,
        this.normalizeNumberDirection(habit.numberDirection),
      ),
    };
  }

  private computeCompleted(
    goalType: 'completion' | 'count' | 'duration' | 'number',
    value: number,
    goalValue?: number | null,
    numberDirection: 'gte' | 'lte' = 'gte',
  ): boolean {
    if (goalType === 'completion') return true;
    if (goalValue == null || !Number.isFinite(Number(goalValue))) {
      return value > 0;
    }
    const goal = Number(goalValue);
    if (goalType === 'number' && numberDirection === 'lte') {
      return value <= goal;
    }
    return value >= goal;
  }
}
