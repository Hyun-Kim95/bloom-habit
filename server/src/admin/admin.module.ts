import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { HabitsModule } from '../habits/habits.module';
import { AdminAuthService } from './admin-auth.service';
import { AdminController } from './admin.controller';
import { AdminDataService } from './admin-data.service';
import { AdminGuard } from './admin.guard';
import { AdminStatsService } from './admin-stats.service';
import { PushModule } from '../push/push.module';
import { AdminUser, HabitTemplate, Inquiry, LegalDocument, Notice, SystemConfig, User, Habit, HabitRecord } from '../entities';

@Module({
  imports: [
    TypeOrmModule.forFeature([AdminUser, HabitTemplate, Inquiry, LegalDocument, Notice, SystemConfig, User, Habit, HabitRecord]),
    AuthModule,
    HabitsModule,
    PushModule,
  ],
  controllers: [AdminController],
  providers: [AdminAuthService, AdminDataService, AdminGuard, AdminStatsService],
})
export class AdminModule {}
