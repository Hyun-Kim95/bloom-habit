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

  /** YYYY-MM-DD (서버 기준 날짜) */
  @Column()
  pushDate: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}

