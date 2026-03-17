import { Repository } from 'typeorm';
import { HabitsService } from './habits.service';
import { AiFeedbackLog } from '../entities';
export declare class AiFeedbackService {
    private readonly habits;
    private readonly feedbackRepo;
    constructor(habits: HabitsService, feedbackRepo: Repository<AiFeedbackLog>);
    requestFeedback(userId: string, habitId: string, recordId: string): Promise<{
        response_text: string;
    }>;
    private callOpenAI;
}
