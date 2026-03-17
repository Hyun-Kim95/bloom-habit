import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('habit_records')
export class HabitRecord {
  @PrimaryColumn()
  id: string;

  @Column()
  habitId: string;

  @Column()
  recordDate: string;

  @Column({ type: 'int', nullable: true })
  value: number | null;

  @Column({ default: false })
  completed: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
