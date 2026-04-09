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

  /** Optional English display name (app + admin). */
  @Column({ type: 'varchar', nullable: true })
  nameEn: string | null;

  @Column({ type: 'varchar', nullable: true })
  category: string | null;

  /** Optional English category label (canonical [category] remains KO for habits). */
  @Column({ type: 'varchar', nullable: true })
  categoryEn: string | null;

  @Column({ default: 'completion' })
  goalType: string;

  @Column({ type: 'double precision', nullable: true })
  goalValue: number | null;

  @Column({ type: 'varchar', nullable: true })
  colorHex: string | null;

  @Column({ type: 'varchar', nullable: true })
  iconName: string | null;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
