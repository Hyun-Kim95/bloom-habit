import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { HabitTemplate } from '../entities';
import { DEFAULT_HABIT_TEMPLATES } from './default-habit-templates';

@Injectable()
export class HabitTemplateSeedService implements OnModuleInit {
  private readonly logger = new Logger(HabitTemplateSeedService.name);

  constructor(
    @InjectRepository(HabitTemplate)
    private readonly repo: Repository<HabitTemplate>,
  ) {}

  async onModuleInit(): Promise<void> {
    const n = await this.repo.count();
    if (n > 0) return;
    for (const row of DEFAULT_HABIT_TEMPLATES) {
      const goalType = row.goalType;
      const goalValue =
        goalType === 'completion'
          ? null
          : row.goalValue != null && Number.isFinite(row.goalValue)
            ? row.goalValue
            : null;
      await this.repo.save(
        this.repo.create({
          id: `t-${uuidv4()}`,
          name: row.name,
          category: row.category,
          goalType,
          goalValue,
          isActive: true,
        }),
      );
    }
    this.logger.log(`예시 습관 템플릿 ${DEFAULT_HABIT_TEMPLATES.length}개를 시드했습니다.`);
  }
}
