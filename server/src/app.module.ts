import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DbRetryInterceptor } from './common/db-retry.interceptor';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { ConfigModule } from './config/config.module';
import { HabitsModule } from './habits/habits.module';
import { InquiriesModule } from './inquiries/inquiries.module';
import { LegalModule } from './legal/legal.module';
import { SyncModule } from './sync/sync.module';
import { StaticAssetsModule } from './static/static-assets.module';
import { PublicNoticesModule } from './notices/public-notices.module';
import { MaintenanceModule } from './maintenance/maintenance.module';
import {
  User,
  Habit,
  HabitRecord,
  AdminUser,
  HabitTemplate,
  Notice,
  SystemConfig,
  Inquiry,
  LegalDocument,
  MissedHabitPushLog,
} from './entities';

@Module({
  imports: [
    ConfigModule,
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
        Inquiry,
        LegalDocument,
        MissedHabitPushLog,
      ],
      synchronize: process.env.NODE_ENV !== 'production',
      extra: {
        connectionTimeoutMillis: 15000,
        idleTimeoutMillis: 30000,
        keepAlive: true,
      },
    }),
    AuthModule,
    HabitsModule,
    InquiriesModule,
    LegalModule,
    SyncModule,
    AdminModule,
    StaticAssetsModule,
    PublicNoticesModule,
    MaintenanceModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    { provide: APP_INTERCEPTOR, useClass: DbRetryInterceptor },
  ],
})
export class AppModule {}
