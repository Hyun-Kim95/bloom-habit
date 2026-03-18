import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { HabitTemplate as HabitTemplateEntity, Inquiry as InquiryEntity, Notice as NoticeEntity, SystemConfig as SystemConfigEntity, User as UserEntity } from '../entities';

export interface InquiryAdminDto {
  id: string;
  userId: string;
  userEmail: string | null;
  userDisplayName: string | null;
  subject: string;
  body: string;
  status: string;
  adminReply: string | null;
  repliedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

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

const DEFAULT_AI_FALLBACK = JSON.stringify([
  '오늘도 수고했어요!',
  '꾸준함이 쌓여가고 있어요.',
  '내일도 화이팅!',
]);

@Injectable()
export class AdminDataService {
  constructor(
    @InjectRepository(HabitTemplateEntity)
    private readonly templateRepo: Repository<HabitTemplateEntity>,
    @InjectRepository(NoticeEntity)
    private readonly noticeRepo: Repository<NoticeEntity>,
    @InjectRepository(SystemConfigEntity)
    private readonly configRepo: Repository<SystemConfigEntity>,
    @InjectRepository(InquiryEntity)
    private readonly inquiryRepo: Repository<InquiryEntity>,
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
  ) {}

  async listTemplates(): Promise<HabitTemplateDto[]> {
    const list = await this.templateRepo.find({ order: { createdAt: 'ASC' } });
    return list.map((t) => ({
      id: t.id,
      name: t.name,
      category: t.category ?? undefined,
      goalType: t.goalType,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    }));
  }

  async createTemplate(body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto> {
    const t = this.templateRepo.create({
      id: `t-${uuidv4()}`,
      name: body.name!,
      category: body.category,
      goalType: body.goalType ?? 'completion',
      isActive: body.isActive ?? true,
    });
    await this.templateRepo.save(t);
    return {
      id: t.id,
      name: t.name,
      category: t.category ?? undefined,
      goalType: t.goalType,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    };
  }

  async updateTemplate(
    id: string,
    body: Partial<HabitTemplateDto>,
  ): Promise<HabitTemplateDto | undefined> {
    const t = await this.templateRepo.findOne({ where: { id } });
    if (!t) return undefined;
    Object.assign(t, body);
    await this.templateRepo.save(t);
    return {
      id: t.id,
      name: t.name,
      category: t.category ?? undefined,
      goalType: t.goalType,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    };
  }

  async deleteTemplate(id: string): Promise<boolean> {
    const result = await this.templateRepo.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async listNotices(): Promise<NoticeDto[]> {
    const list = await this.noticeRepo.find({ order: { createdAt: 'DESC' } });
    return list.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      publishedAt: n.publishedAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    }));
  }

  async createNotice(body: { title: string; body: string; publishedAt?: string }): Promise<NoticeDto> {
    const n = this.noticeRepo.create({
      id: `n-${uuidv4()}`,
      title: body.title,
      body: body.body,
      publishedAt: body.publishedAt ? new Date(body.publishedAt) : null,
    });
    await this.noticeRepo.save(n);
    return {
      id: n.id,
      title: n.title,
      body: n.body,
      publishedAt: n.publishedAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    };
  }

  async updateNotice(id: string, body: Partial<NoticeDto>): Promise<NoticeDto | undefined> {
    const n = await this.noticeRepo.findOne({ where: { id } });
    if (!n) return undefined;
    if (body.title != null) n.title = body.title;
    if (body.body != null) n.body = body.body;
    if (body.publishedAt != null) n.publishedAt = new Date(body.publishedAt);
    await this.noticeRepo.save(n);
    return {
      id: n.id,
      title: n.title,
      body: n.body,
      publishedAt: n.publishedAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    };
  }

  async deleteNotice(id: string): Promise<boolean> {
    const result = await this.noticeRepo.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async getConfig(key: string): Promise<string | undefined> {
    const row = await this.configRepo.findOne({ where: { key } });
    return row?.value;
  }

  async getAllConfig(): Promise<Record<string, string>> {
    const rows = await this.configRepo.find();
    const out: Record<string, string> = {};
    for (const r of rows) out[r.key] = r.value;
    if (!('ai_fallback_messages' in out)) {
      out.ai_fallback_messages = DEFAULT_AI_FALLBACK;
    }
    return out;
  }

  async setConfig(key: string, value: string): Promise<void> {
    let row = await this.configRepo.findOne({ where: { key } });
    if (!row) {
      row = this.configRepo.create({ key, value });
    } else {
      row.value = value;
    }
    await this.configRepo.save(row);
  }

  async patchConfig(body: Record<string, string>): Promise<void> {
    for (const [k, v] of Object.entries(body)) {
      await this.setConfig(k, typeof v === 'string' ? v : JSON.stringify(v));
    }
  }

  async listInquiries(): Promise<InquiryAdminDto[]> {
    const list = await this.inquiryRepo.find({
      order: { createdAt: 'DESC' },
    });
    const userIds = [...new Set(list.map((i) => i.userId))];
    const users = userIds.length
      ? await this.userRepo.find({ where: { id: In(userIds) } })
      : [];
    const userMap = new Map(users.map((u) => [u.id, u]));
    return list.map((i) => {
      const u = userMap.get(i.userId);
      return {
        id: i.id,
        userId: i.userId,
        userEmail: u?.email ?? null,
        userDisplayName: u?.displayName ?? null,
        subject: i.subject,
        body: i.body,
        status: i.status,
        adminReply: i.adminReply ?? null,
        repliedAt: i.repliedAt?.toISOString() ?? null,
        createdAt: i.createdAt.toISOString(),
        updatedAt: i.updatedAt.toISOString(),
      };
    });
  }

  async updateInquiryReply(
    id: string,
    body: { adminReply?: string; status?: string },
  ): Promise<InquiryAdminDto | undefined> {
    const i = await this.inquiryRepo.findOne({ where: { id } });
    if (!i) return undefined;
    if (body.adminReply != null) i.adminReply = body.adminReply;
    if (body.status != null) i.status = body.status;
    if (body.adminReply != null) i.repliedAt = new Date();
    await this.inquiryRepo.save(i);
    const u = await this.userRepo.findOne({ where: { id: i.userId } });
    return {
      id: i.id,
      userId: i.userId,
      userEmail: u?.email ?? null,
      userDisplayName: u?.displayName ?? null,
      subject: i.subject,
      body: i.body,
      status: i.status,
      adminReply: i.adminReply ?? null,
      repliedAt: i.repliedAt?.toISOString() ?? null,
      createdAt: i.createdAt.toISOString(),
      updatedAt: i.updatedAt.toISOString(),
    };
  }
}
