import { AuthService } from '../auth/auth.service';
import { HabitsService } from '../habits/habits.service';
import { AdminAuthService } from './admin-auth.service';
import { AdminDataService, HabitTemplateDto, NoticeDto } from './admin-data.service';
export declare class AdminController {
    private readonly adminAuth;
    private readonly adminData;
    private readonly auth;
    private readonly habits;
    constructor(adminAuth: AdminAuthService, adminData: AdminDataService, auth: AuthService, habits: HabitsService);
    login(body: {
        email: string;
        password: string;
    }): Promise<{
        accessToken: string;
    }>;
    users(): Promise<{
        id: string;
        email: string | null;
        displayName: string | null;
    }[]>;
    stats(): Promise<{
        totalUsers: number;
        totalHabits: number;
        totalRecords: number;
    }>;
    listTemplates(): Promise<HabitTemplateDto[]>;
    createTemplate(body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto>;
    updateTemplate(id: string, body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto | {
        statusCode: number;
        message: string;
    }>;
    deleteTemplate(id: string): Promise<{
        statusCode: number;
        message: string;
        ok?: undefined;
    } | {
        ok: boolean;
        statusCode?: undefined;
        message?: undefined;
    }>;
    listNotices(): Promise<NoticeDto[]>;
    createNotice(body: {
        title: string;
        body: string;
        publishedAt?: string;
    }): Promise<NoticeDto>;
    updateNotice(id: string, body: Partial<NoticeDto>): Promise<NoticeDto | {
        statusCode: number;
        message: string;
    }>;
    deleteNotice(id: string): Promise<{
        statusCode: number;
        message: string;
        ok?: undefined;
    } | {
        ok: boolean;
        statusCode?: undefined;
        message?: undefined;
    }>;
    getConfig(): Promise<Record<string, string>>;
    patchConfig(body: Record<string, string>): Promise<Record<string, string>>;
}
