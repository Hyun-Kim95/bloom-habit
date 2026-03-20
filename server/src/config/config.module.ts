import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HabitTemplate, SystemConfig } from '../entities';
import { ConfigSeedService } from './config-seed.service';
import { ConfigService } from './config.service';
import { HabitTemplateSeedService } from './habit-template-seed.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([SystemConfig, HabitTemplate])],
  providers: [ConfigService, ConfigSeedService, HabitTemplateSeedService],
  exports: [ConfigService],
})
export class ConfigModule {}
