import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SystemConfig } from '../entities';

/**
 * 시스템 설정 조회 (Auth, AI 등에서 사용).
 * 관리자 페이지에서 PATCH /admin/system-config 로 저장한 값을 읽습니다.
 */
@Injectable()
export class ConfigService {
  constructor(
    @InjectRepository(SystemConfig)
    private readonly repo: Repository<SystemConfig>,
  ) {}

  async get(key: string): Promise<string | undefined> {
    const row = await this.repo.findOne({ where: { key } });
    return row?.value;
  }

  async set(key: string, value: string): Promise<void> {
    await this.repo.upsert({ key, value }, { conflictPaths: ['key'] });
  }
}
