import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { LegalDocument } from '../entities';
import type { LegalDocumentType } from '../entities/legal-document.entity';
import { DEFAULT_PRIVACY_CONTENT, DEFAULT_TERMS_CONTENT } from './default-legal-content';
import { DEFAULT_PRIVACY_CONTENT_EN, DEFAULT_TERMS_CONTENT_EN } from './default-legal-content-en';

@Injectable()
export class LegalSeedService implements OnModuleInit {
  private readonly logger = new Logger(LegalSeedService.name);

  constructor(
    @InjectRepository(LegalDocument)
    private readonly repo: Repository<LegalDocument>,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.ensureDefaultContent('terms', DEFAULT_TERMS_CONTENT, 'ko');
    await this.ensureDefaultContent('privacy', DEFAULT_PRIVACY_CONTENT, 'ko');
    await this.ensureDefaultContent('terms', DEFAULT_TERMS_CONTENT_EN, 'en');
    await this.ensureDefaultContent('privacy', DEFAULT_PRIVACY_CONTENT_EN, 'en');
  }

  /** If no rows for (type, locale), or all rows have empty content, seed default text. */
  private async ensureDefaultContent(
    type: LegalDocumentType,
    content: string,
    locale: 'ko' | 'en',
  ): Promise<void> {
    const total = await this.repo.count({ where: { type, locale } });
    if (total === 0) {
      await this.insertVersion(type, 1, content, locale);
      this.logger.log(`Seeded default ${type} document v1 (${locale}).`);
      return;
    }
    const withContent = await this.repo
      .createQueryBuilder('d')
      .where('d.type = :type', { type })
      .andWhere('d.locale = :locale', { locale })
      .andWhere("TRIM(d.content) <> ''")
      .getCount();
    if (withContent > 0) return;
    const maxRow = await this.repo
      .createQueryBuilder('d')
      .select('MAX(d.version)', 'max')
      .where('d.type = :type', { type })
      .andWhere('d.locale = :locale', { locale })
      .getRawOne<{ max: string | null }>();
    const nextV = (maxRow?.max != null ? parseInt(String(maxRow.max), 10) : 0) + 1;
    await this.insertVersion(type, nextV, content, locale);
    this.logger.log(`Added default ${type} content as v${nextV} (${locale}).`);
  }

  private async insertVersion(
    type: LegalDocumentType,
    version: number,
    content: string,
    locale: 'ko' | 'en',
  ): Promise<void> {
    await this.repo.save(
      this.repo.create({
        id: `legal-${uuidv4()}`,
        type,
        locale,
        version,
        title: '',
        content,
        effectiveFrom: null,
      }),
    );
  }
}
