import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
import { MeController } from './me.controller';
import { InquiriesModule } from '../inquiries/inquiries.module';
import { User, Habit, HabitRecord, Inquiry, Notice, NoticeRead } from '../entities';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Habit, HabitRecord, Inquiry, Notice, NoticeRead]),
    InquiriesModule,
  ],
  controllers: [AuthController, MeController],
  providers: [AuthService, JwtGuard],
  exports: [AuthService],
})
export class AuthModule {}
