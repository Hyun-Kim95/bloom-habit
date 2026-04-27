import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUnreadTracking1777400000000 implements MigrationInterface {
  name = 'AddUnreadTracking1777400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "inquiries" ADD "userReadAt" TIMESTAMP WITH TIME ZONE');
    await queryRunner.query(
      'CREATE TABLE "notice_reads" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" character varying NOT NULL, "noticeId" character varying NOT NULL, "readAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_notice_reads_user_notice" UNIQUE ("userId", "noticeId"), CONSTRAINT "PK_notice_reads_id" PRIMARY KEY ("id"))',
    );
    await queryRunner.query(
      'CREATE INDEX "IDX_notice_reads_userId" ON "notice_reads" ("userId") ',
    );
    await queryRunner.query(
      'CREATE INDEX "IDX_notice_reads_noticeId" ON "notice_reads" ("noticeId") ',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX "public"."IDX_notice_reads_noticeId"');
    await queryRunner.query('DROP INDEX "public"."IDX_notice_reads_userId"');
    await queryRunner.query('DROP TABLE "notice_reads"');
    await queryRunner.query('ALTER TABLE "inquiries" DROP COLUMN "userReadAt"');
  }
}
