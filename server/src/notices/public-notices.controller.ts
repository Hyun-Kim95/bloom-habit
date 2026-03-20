import { Controller, Get } from '@nestjs/common';
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
  async listPublished() {
    const now = new Date();
    const list = await this.noticeRepo
      .createQueryBuilder('n')
      .where('n.publishedAt IS NOT NULL')
      .andWhere('n.publishedAt <= :now', { now })
      .orderBy('n.publishedAt', 'DESC')
      .getMany();
    return list.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      publishedAt: n.publishedAt!.toISOString(),
    }));
  }
}
