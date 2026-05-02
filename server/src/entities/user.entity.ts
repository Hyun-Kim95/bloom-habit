import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryColumn()
  id: string;

  @Column({ type: 'varchar', nullable: true })
  email: string | null;

  /** 이메일이 설정된 시각(OAuth 동기화 또는 앱에서 등록). */
  @Column({ type: 'timestamptz', nullable: true })
  emailVerifiedAt: Date | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  authProvider: 'google' | 'apple' | 'kakao' | 'naver' | null;

  @Column({ type: 'varchar', nullable: true })
  displayName: string | null;

  @Column({ type: 'varchar', length: 2048, nullable: true })
  avatarUrl: string | null;

  @Column({ type: 'varchar', length: 512, nullable: true })
  fcmToken: string | null;

  /** IANA 타임존 (예: Asia/Seoul). null이면 미달성 푸시 시 Asia/Seoul로 간주. */
  @Column({ type: 'varchar', length: 64, nullable: true })
  ianaTimeZone: string | null;

  /** 미달성 요약 FCM 로컬 시각(시). null이면 서버 env 기본. */
  @Column({ type: 'smallint', nullable: true })
  missedHabitPushLocalHour: number | null;

  /** 미달성 요약 FCM 로컬 시각(분). null이면 서버 env 기본. */
  @Column({ type: 'smallint', nullable: true })
  missedHabitPushLocalMinute: number | null;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  deactivatedAt: Date | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  deactivationReason: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  deactivatedBy: 'self' | 'admin' | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
