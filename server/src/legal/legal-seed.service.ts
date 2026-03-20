import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { LegalDocument } from '../entities';
import type { LegalDocumentType } from '../entities/legal-document.entity';
import { DEFAULT_PRIVACY_CONTENT, DEFAULT_TERMS_CONTENT } from './default-legal-content';

@Injectable()
export class LegalSeedService implements OnModuleInit {
  private readonly logger = new Logger(LegalSeedService.name);

  constructor(
    @InjectRepository(LegalDocument)
    private readonly repo: Repository<LegalDocument>,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.ensureDefaultContent('terms', DEFAULT_TERMS_CONTENT);
    await this.ensureDefaultContent('privacy', DEFAULT_PRIVACY_CONTENT);
  }

  /** 해당 타입에 본문이 하나도 없으면(또는 행이 없으면) 기본 문구를 넣습니다. */
  private async ensureDefaultContent(type: LegalDocumentType, content: string): Promise<void> {
    const total = await this.repo.count({ where: { type } });
    if (total === 0) {
      await this.insertVersion(type, 1, content);
      this.logger.log(`기본 ${type} 문서(v1)를 시드했습니다.`);
      return;
    }
    const withContent = await this.repo
      .createQueryBuilder('d')
      .where('d.type = :type', { type })
      .andWhere("TRIM(d.content) <> ''")
      .getCount();
    if (withContent > 0) return;
    const maxRow = await this.repo
      .createQueryBuilder('d')
      .select('MAX(d.version)', 'max')
      .where('d.type = :type', { type })
      .getRawOne<{ max: string | null }>();
    const nextV = (maxRow?.max != null ? parseInt(String(maxRow.max), 10) : 0) + 1;
    await this.insertVersion(type, nextV, content);
    this.logger.log(`${type}에 본문이 없어 v${nextV}로 기본 문구를 추가했습니다.`);
  }

  private async insertVersion(type: LegalDocumentType, version: number, content: string): Promise<void> {
    await this.repo.save(
      this.repo.create({
        id: `legal-${uuidv4()}`,
        type,
        version,
        title: '',
        content,
        effectiveFrom: null,
      }),
    );
  }
}
