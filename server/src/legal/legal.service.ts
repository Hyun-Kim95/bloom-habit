import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LegalDocument } from '../entities';
import type { LegalDocumentType } from '../entities/legal-document.entity';

export interface LegalDocumentPublicDto {
  id: string;
  type: LegalDocumentType;
  version: number;
  title: string;
  content: string;
  effectiveFrom: string | null;
  updatedAt: string;
}

@Injectable()
export class LegalService {
  constructor(
    @InjectRepository(LegalDocument)
    private readonly repo: Repository<LegalDocument>,
  ) {}

  async getLatest(type: LegalDocumentType): Promise<LegalDocumentPublicDto | null> {
    const doc = await this.repo.findOne({
      where: { type },
      order: { version: 'DESC' },
    });
    if (!doc) return null;
    return {
      id: doc.id,
      type: doc.type,
      version: doc.version,
      title: doc.title,
      content: doc.content,
      effectiveFrom: doc.effectiveFrom?.toISOString().slice(0, 10) ?? null,
      updatedAt: doc.updatedAt.toISOString(),
    };
  }
}
