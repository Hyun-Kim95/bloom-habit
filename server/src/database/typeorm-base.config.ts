import type { DataSourceOptions } from 'typeorm';
import {
  User,
  Habit,
  HabitRecord,
  AdminUser,
  HabitTemplate,
  Notice,
  NoticeRead,
  SystemConfig,
  Inquiry,
  LegalDocument,
  MissedHabitPushLog,
} from '../entities';

/** 엔티티 목록 — AppModule / TypeORM CLI DataSource 에서 공통 사용 */
export const typeOrmEntities = [
  User,
  Habit,
  HabitRecord,
  AdminUser,
  HabitTemplate,
  Notice,
  NoticeRead,
  SystemConfig,
  Inquiry,
  LegalDocument,
  MissedHabitPushLog,
];

export const typeOrmConnectionExtras: DataSourceOptions['extra'] = {
  connectionTimeoutMillis: 15000,
  idleTimeoutMillis: 30000,
  keepAlive: true,
};

/** 프로덕션에서 엔티티 자동 동기화 여부 (마이그레이션 사용 시 false 권장) */
export function typeOrmSynchronize(): boolean {
  if (process.env.TYPEORM_SYNC === 'true') return true;
  if (process.env.TYPEORM_SYNC === 'false') return false;
  return process.env.NODE_ENV !== 'production';
}
