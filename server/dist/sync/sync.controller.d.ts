import { Request } from 'express';
import { HabitsService } from '../habits/habits.service';
type ReqWithUser = Request & {
    userId: string;
};
export declare class SyncController {
    private readonly habits;
    constructor(habits: HabitsService);
    sync(req: ReqWithUser, _since?: string): Promise<{
        users: never[];
        habits: import("../habits/habits.service").HabitDto[];
        records: import("../habits/habits.service").RecordDto[];
    }>;
}
export {};
