import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, Unique } from 'typeorm';

@Entity('notice_reads')
@Unique('UQ_notice_reads_user_notice', ['userId', 'noticeId'])
export class NoticeRead {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  noticeId: string;

  @CreateDateColumn({ type: 'timestamptz' })
  readAt: Date;
}
