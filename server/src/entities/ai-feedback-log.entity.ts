import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('ai_feedback_logs')
export class AiFeedbackLog {
  @PrimaryColumn()
  id: string;

  @Column()
  userId: string;

  @Column()
  habitId: string;

  @Column()
  recordDate: string;

  @Column()
  recordId: string;

  @Column({ type: 'text' })
  responseText: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
