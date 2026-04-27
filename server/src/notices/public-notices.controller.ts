import { Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { Request } from 'express';
import { JwtGuard } from '../auth/jwt.guard';
import { Notice, NoticeRead } from '../entities';

type ReqWithUser = Request & { userId: string };

@Controller('notices')
export class PublicNoticesController {
  constructor(
    @InjectRepository(Notice)
    private readonly noticeRepo: Repository<Notice>,
    @InjectRepository(NoticeRead)
    private readonly noticeReadRepo: Repository<NoticeRead>,
  ) {}

  /** 게시된 공지만 (publishedAt 있음·현재 시각 이전) */
  @Get()
  async listPublished(@Query('locale') locale?: string) {
    const preferEn = locale === 'en';
    const now = new Date();
    const list = await this.noticeRepo
      .createQueryBuilder('n')
      .where('n.publishedAt IS NOT NULL')
      .andWhere('n.publishedAt <= :now', { now })
      .orderBy('n.publishedAt', 'DESC')
      .getMany();
    return list.map((n) => {
      const titleEn = n.titleEn?.trim();
      const bodyEn = n.bodyEn?.trim();
      return {
        id: n.id,
        title: preferEn && titleEn ? titleEn : n.title,
        body: preferEn && bodyEn ? bodyEn : n.body,
        titleEn: n.titleEn ?? undefined,
        bodyEn: n.bodyEn ?? undefined,
        publishedAt: n.publishedAt!.toISOString(),
      };
    });
  }

  @Post(':id/read')
  @UseGuards(JwtGuard)
  async markNoticeRead(@Req() req: ReqWithUser, @Param('id') id: string) {
    const now = new Date();
    await this.noticeReadRepo
      .createQueryBuilder()
      .insert()
      .values({ userId: req.userId, noticeId: id, readAt: now })
      .orUpdate(['readAt'], ['userId', 'noticeId'])
      .execute();
    return { ok: true };
  }

  @Get('unread-count')
  @UseGuards(JwtGuard)
  async unreadCount(@Req() req: ReqWithUser) {
    const now = new Date();
    const row = await this.noticeRepo
      .createQueryBuilder('n')
      .leftJoin(
        NoticeRead,
        'nr',
        'nr.noticeId = n.id AND nr.userId = :userId',
        { userId: req.userId },
      )
      .select('COUNT(1)', 'count')
      .where('n.publishedAt IS NOT NULL')
      .andWhere('n.publishedAt <= :now', { now })
      .andWhere('nr.id IS NULL')
      .getRawOne<{ count: string }>();
    return { unreadCount: Number(row?.count ?? 0) };
  }
}
