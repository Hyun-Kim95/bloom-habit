import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HabitsController } from './habits.controller';
import { HabitsService } from './habits.service';
import { Habit, HabitRecord, HabitTemplate } from '../entities';

@Module({
  imports: [TypeOrmModule.forFeature([Habit, HabitRecord, HabitTemplate])],
  controllers: [HabitsController],
  providers: [HabitsService],
  exports: [HabitsService],
})
export class HabitsModule {}
