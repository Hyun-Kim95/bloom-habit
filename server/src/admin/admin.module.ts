import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { HabitsModule } from '../habits/habits.module';
import { AdminAuthService } from './admin-auth.service';
import { AdminController } from './admin.controller';
import { AdminDataService } from './admin-data.service';
import { AdminGuard } from './admin.guard';
import { AdminUser, HabitTemplate, Notice, SystemConfig } from '../entities';

@Module({
  imports: [
    TypeOrmModule.forFeature([AdminUser, HabitTemplate, Notice, SystemConfig]),
    AuthModule,
    HabitsModule,
  ],
  controllers: [AdminController],
  providers: [AdminAuthService, AdminDataService, AdminGuard],
})
export class AdminModule {}
