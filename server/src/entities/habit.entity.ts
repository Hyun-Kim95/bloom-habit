import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('habits')
export class Habit {
  @PrimaryColumn()
  id: string;

  @Column()
  userId: string;

  @Column()
  name: string;

  @Column({ type: 'varchar', nullable: true })
  category: string | null;

  @Column({ default: 'completion' })
  goalType: string;

  @Column({ type: 'int', nullable: true })
  goalValue: number | null;

  @Column()
  startDate: string;

  @Column({ type: 'varchar', nullable: true })
  colorHex: string | null;

  @Column({ type: 'varchar', nullable: true })
  iconName: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  archivedAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
