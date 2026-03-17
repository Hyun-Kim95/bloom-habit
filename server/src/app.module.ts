import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { HabitsModule } from './habits/habits.module';
import { SyncModule } from './sync/sync.module';
import {
  User,
  Habit,
  HabitRecord,
  AdminUser,
  HabitTemplate,
  Notice,
  SystemConfig,
  AiFeedbackLog,
} from './entities';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [
        User,
        Habit,
        HabitRecord,
        AdminUser,
        HabitTemplate,
        Notice,
        SystemConfig,
        AiFeedbackLog,
      ],
      synchronize: process.env.NODE_ENV !== 'production',
      extra: { connectionTimeoutMillis: 10000 },
    }),
    AuthModule,
    HabitsModule,
    SyncModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
