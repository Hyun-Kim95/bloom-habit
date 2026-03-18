import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from './config.service';

const HABIT_CATEGORIES_KEY = 'habit_categories';

const DEFAULT_HABIT_CATEGORIES = [
  '건강',
  '운동',
  '독서',
  '학습',
  '명상',
  '취미',
  '업무',
  '생활',
];

@Injectable()
export class ConfigSeedService implements OnModuleInit {
  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const existing = await this.config.get(HABIT_CATEGORIES_KEY);
    if (existing != null && existing.trim() !== '') return;
    await this.config.set(
      HABIT_CATEGORIES_KEY,
      JSON.stringify(DEFAULT_HABIT_CATEGORIES),
    );
  }
}
