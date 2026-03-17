import { Repository } from 'typeorm';
import { HabitTemplate as HabitTemplateEntity, Notice as NoticeEntity, SystemConfig as SystemConfigEntity } from '../entities';
export interface HabitTemplateDto {
    id: string;
    name: string;
    category?: string;
    goalType: string;
    isActive: boolean;
    createdAt: string;
    updatedAt: string;
}
export interface NoticeDto {
    id: string;
    title: string;
    body: string;
    publishedAt?: string;
    createdAt: string;
    updatedAt: string;
}
export declare class AdminDataService {
    private readonly templateRepo;
    private readonly noticeRepo;
    private readonly configRepo;
    constructor(templateRepo: Repository<HabitTemplateEntity>, noticeRepo: Repository<NoticeEntity>, configRepo: Repository<SystemConfigEntity>);
    listTemplates(): Promise<HabitTemplateDto[]>;
    createTemplate(body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto>;
    updateTemplate(id: string, body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto | undefined>;
    deleteTemplate(id: string): Promise<boolean>;
    listNotices(): Promise<NoticeDto[]>;
    createNotice(body: {
        title: string;
        body: string;
        publishedAt?: string;
    }): Promise<NoticeDto>;
    updateNotice(id: string, body: Partial<NoticeDto>): Promise<NoticeDto | undefined>;
    deleteNotice(id: string): Promise<boolean>;
    getConfig(key: string): Promise<string | undefined>;
    getAllConfig(): Promise<Record<string, string>>;
    setConfig(key: string, value: string): Promise<void>;
    patchConfig(body: Record<string, string>): Promise<void>;
}
