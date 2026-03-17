import { Repository } from 'typeorm';
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
export declare class HabitsService {
    private readonly habitRepo;
    private readonly recordRepo;
    constructor(habitRepo: Repository<HabitEntity>, recordRepo: Repository<HabitRecordEntity>);
    list(userId: string, archived?: boolean): Promise<HabitDto[]>;
    get(id: string, userId: string): Promise<HabitDto | undefined>;
    create(userId: string, body: {
        name: string;
        category?: string;
        goalType: string;
        goalValue?: number;
        startDate: string;
        colorHex?: string;
        iconName?: string;
    }): Promise<HabitDto>;
    update(id: string, userId: string, body: Partial<Pick<HabitDto, 'name' | 'category' | 'goalType' | 'goalValue' | 'colorHex' | 'iconName'>>): Promise<HabitDto | undefined>;
    delete(id: string, userId: string): Promise<boolean>;
    archive(id: string, userId: string): Promise<HabitDto | undefined>;
    getRecord(recordId: string, userId: string): Promise<RecordDto | undefined>;
    listRecords(habitId: string, userId: string, from?: string, to?: string): Promise<RecordDto[]>;
    addRecord(habitId: string, userId: string, body: {
        recordDate: string;
        value?: number;
        completed: boolean;
    }): Promise<RecordDto | undefined>;
    getSyncPayload(userId: string, _since?: string): Promise<{
        habits: HabitDto[];
        records: RecordDto[];
    }>;
    getTotalCounts(): Promise<{
        totalHabits: number;
        totalRecords: number;
    }>;
}
