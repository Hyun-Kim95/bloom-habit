import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiFeedbackService } from './ai-feedback.service';
import { HabitsController } from './habits.controller';
import { HabitsService } from './habits.service';
import { Habit, HabitRecord, AiFeedbackLog } from '../entities';

@Module({
  imports: [TypeOrmModule.forFeature([Habit, HabitRecord, AiFeedbackLog])],
  controllers: [HabitsController],
  providers: [HabitsService, AiFeedbackService],
  exports: [HabitsService],
})
export class HabitsModule {}
