import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export type LegalDocumentType = 'terms' | 'privacy';

@Entity('legal_documents')
export class LegalDocument {
  @PrimaryColumn()
  id: string;

  @Column({ type: 'varchar', length: 20 })
  type: LegalDocumentType;

  @Column({ type: 'int', default: 1 })
  version: number;

  @Column({ type: 'varchar', length: 255, default: '' })
  title: string;

  @Column({ type: 'text', default: '' })
  content: string;

  @Column({ type: 'date', nullable: true })
  effectiveFrom: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
