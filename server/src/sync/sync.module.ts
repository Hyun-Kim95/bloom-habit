import { Module } from '@nestjs/common';
import { HabitsModule } from '../habits/habits.module';
import { SyncController } from './sync.controller';

@Module({
  imports: [HabitsModule],
  controllers: [SyncController],
})
export class SyncModule {}
