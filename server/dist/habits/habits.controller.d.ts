import { Request } from 'express';
import { AiFeedbackService } from './ai-feedback.service';
import { HabitsService, HabitDto, RecordDto } from './habits.service';
type ReqWithUser = Request & {
    userId: string;
};
export declare class HabitsController {
    private readonly habits;
    private readonly aiFeedbackService;
    constructor(habits: HabitsService, aiFeedbackService: AiFeedbackService);
    list(req: ReqWithUser, archived?: string): Promise<HabitDto[]>;
    get(req: ReqWithUser, id: string): Promise<HabitDto | {
        statusCode: number;
        message: string;
    }>;
    create(req: ReqWithUser, body: Partial<HabitDto>): Promise<HabitDto>;
    update(req: ReqWithUser, id: string, body: Partial<HabitDto>): Promise<HabitDto | {
        statusCode: number;
        message: string;
    }>;
    delete(req: ReqWithUser, id: string): Promise<{
        statusCode: number;
        message: string;
        ok?: undefined;
    } | {
        ok: boolean;
        statusCode?: undefined;
        message?: undefined;
    }>;
    listRecords(req: ReqWithUser, habitId: string, from?: string, to?: string): Promise<RecordDto[]>;
    addRecord(req: ReqWithUser, habitId: string, body: {
        recordDate: string;
        value?: number;
        completed: boolean;
    }): Promise<RecordDto | {
        statusCode: number;
        message: string;
    }>;
    aiFeedback(req: ReqWithUser, habitId: string, recordId: string): Promise<{
        response_text: string;
    } | {
        statusCode: number;
        message: string;
    }>;
}
export {};
