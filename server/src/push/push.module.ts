import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Habit, HabitRecord, MissedHabitPushLog, User } from '../entities';
import { PushService } from './push.service';
import { MissedHabitReminderScheduler } from './missed-habit-reminder.scheduler';

@Module({
  imports: [TypeOrmModule.forFeature([User, Habit, HabitRecord, MissedHabitPushLog])],
  providers: [PushService, MissedHabitReminderScheduler],
  exports: [PushService, MissedHabitReminderScheduler],
})
export class PushModule {}
