import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('habit_templates')
export class HabitTemplate {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ type: 'varchar', nullable: true })
  category: string | null;

  @Column({ default: 'completion' })
  goalType: string;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
