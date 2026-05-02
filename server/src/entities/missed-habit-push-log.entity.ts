import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('missed_habit_push_logs')
@Index(['userId', 'pushDate'], { unique: true })
export class MissedHabitPushLog {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: string;

  /** YYYY-MM-DD — 해당 유저 로컬 달력 기준 전송일(미달성 판정과 동일). */
  @Column()
  pushDate: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

