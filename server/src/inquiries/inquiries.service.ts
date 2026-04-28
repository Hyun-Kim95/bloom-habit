import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Inquiry } from '../entities';

export interface InquiryDto {
  id: string;
  userId: string;
  subject: string;
  body: string;
  status: string;
  adminReply: string | null;
  repliedAt: string | null;
  userReadAt: string | null;
  createdAt: string;
  updatedAt: string;
}

@Injectable()
export class InquiriesService {
  constructor(
    @InjectRepository(Inquiry)
    private readonly repo: Repository<Inquiry>,
  ) {}

  async create(userId: string, subject: string, body: string): Promise<InquiryDto> {
    const e = this.repo.create({
      id: `inq-${uuidv4()}`,
      userId,
      subject,
      body,
      status: 'pending',
      userReadAt: null,
    });
    await this.repo.save(e);
    return this.toDto(e);
  }

  async listByUser(userId: string): Promise<InquiryDto[]> {
    const list = await this.repo
      .createQueryBuilder('i')
      .where('i.userId = :userId', { userId })
      .andWhere('i.deletedAt IS NULL')
      .orderBy('i.createdAt', 'DESC')
      .getMany();
    return list.map((e) => this.toDto(e));
  }

  async listAll(): Promise<(InquiryDto & { userEmail?: string; userDisplayName?: string })[]> {
    const list = await this.repo
      .createQueryBuilder('i')
      .where('i.deletedAt IS NULL')
      .orderBy('i.createdAt', 'DESC')
      .getMany();
    return list.map((e) => this.toDto(e));
  }

  async getOne(id: string): Promise<InquiryDto | undefined> {
    const e = await this.repo.findOne({ where: { id } });
    return e ? this.toDto(e) : undefined;
  }

  async updateReply(
    id: string,
    body: { adminReply?: string; status?: string },
  ): Promise<InquiryDto | undefined> {
    const e = await this.repo.findOne({ where: { id } });
    if (!e) return undefined;
    if (body.adminReply != null) e.adminReply = body.adminReply;
    if (body.status != null) e.status = body.status;
    if (body.adminReply != null) {
      e.repliedAt = new Date();
      if ((body.adminReply ?? '').trim() !== '') {
        e.status = 'answered';
        // 새 답변/수정 답변이 달리면 사용자 확인 상태를 초기화한다.
        e.userReadAt = null;
      }
    }
    await this.repo.save(e);
    return this.toDto(e);
  }

  async markAsRead(userId: string, inquiryId: string): Promise<boolean> {
    const inquiry = await this.repo.findOne({
      where: { id: inquiryId, userId, deletedAt: IsNull() },
    });
    if (!inquiry) return false;
    inquiry.userReadAt = new Date();
    await this.repo.save(inquiry);
    return true;
  }

  async countUnreadAnsweredByUser(userId: string): Promise<number> {
    const row = await this.repo
      .createQueryBuilder('i')
      .select('COUNT(1)', 'count')
      .where('i.userId = :userId', { userId })
      .andWhere('i.deletedAt IS NULL')
      .andWhere("i.status = 'answered'")
      .andWhere(
        '(i.userReadAt IS NULL OR (i.repliedAt IS NOT NULL AND i.userReadAt < i.repliedAt))',
      )
      .getRawOne<{ count: string }>();
    return Number(row?.count ?? 0);
  }

  async updateOwnInquiry(
    userId: string,
    inquiryId: string,
    body: { subject?: string; body?: string },
  ): Promise<InquiryDto | undefined> {
    const inquiry = await this.repo.findOne({
      where: { id: inquiryId, userId, deletedAt: IsNull() },
    });
    if (!inquiry) return undefined;
    if (inquiry.status !== 'pending') return undefined;
    if (body.subject !== undefined) inquiry.subject = body.subject.trim();
    if (body.body !== undefined) inquiry.body = body.body.trim();
    await this.repo.save(inquiry);
    return this.toDto(inquiry);
  }

  async softDeleteOwnInquiry(userId: string, inquiryId: string): Promise<boolean> {
    const inquiry = await this.repo.findOne({
      where: { id: inquiryId, userId, deletedAt: IsNull() },
    });
    if (!inquiry) return false;
    inquiry.deletedAt = new Date();
    await this.repo.save(inquiry);
    return true;
  }

  private toDto(e: Inquiry): InquiryDto {
    return {
      id: e.id,
      userId: e.userId,
      subject: e.subject,
      body: e.body,
      status: e.status,
      adminReply: e.adminReply ?? null,
      repliedAt: e.repliedAt?.toISOString() ?? null,
      userReadAt: e.userReadAt?.toISOString() ?? null,
      createdAt: e.createdAt.toISOString(),
      updatedAt: e.updatedAt.toISOString(),
    };
  }
}
