import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
import { MeController } from './me.controller';
import { User, Habit, HabitRecord, AiFeedbackLog } from '../entities';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Habit, HabitRecord, AiFeedbackLog]),
  ],
  controllers: [AuthController, MeController],
  providers: [AuthService, JwtGuard],
  exports: [AuthService],
})
export class AuthModule {}
