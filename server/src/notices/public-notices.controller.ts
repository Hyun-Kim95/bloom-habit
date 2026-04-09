import { Controller, Get, Query } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notice } from '../entities';

@Controller('notices')
export class PublicNoticesController {
  constructor(
    @InjectRepository(Notice)
    private readonly noticeRepo: Repository<Notice>,
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
}
