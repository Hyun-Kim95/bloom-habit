import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExpandInquiryAndNoticePolicy1777401000000 implements MigrationInterface {
  name = 'ExpandInquiryAndNoticePolicy1777401000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "inquiries" ADD "deletedAt" TIMESTAMP WITH TIME ZONE');
    await queryRunner.query('CREATE INDEX "IDX_inquiries_deletedAt" ON "inquiries" ("deletedAt") ');

    await queryRunner.query('ALTER TABLE "notices" ADD "isNotice" boolean NOT NULL DEFAULT true');
    await queryRunner.query('ALTER TABLE "notices" ADD "isPublic" boolean NOT NULL DEFAULT false');
    await queryRunner.query('ALTER TABLE "notices" ADD "displayStartAt" TIMESTAMP WITH TIME ZONE');
    await queryRunner.query('ALTER TABLE "notices" ADD "displayEndAt" TIMESTAMP WITH TIME ZONE');
    await queryRunner.query('CREATE INDEX "IDX_notices_isNotice_isPublic" ON "notices" ("isNotice", "isPublic") ');
    await queryRunner.query('CREATE INDEX "IDX_notices_displayStartAt" ON "notices" ("displayStartAt") ');
    await queryRunner.query('CREATE INDEX "IDX_notices_displayEndAt" ON "notices" ("displayEndAt") ');
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX "public"."IDX_notices_displayEndAt"');
    await queryRunner.query('DROP INDEX "public"."IDX_notices_displayStartAt"');
    await queryRunner.query('DROP INDEX "public"."IDX_notices_isNotice_isPublic"');
    await queryRunner.query('ALTER TABLE "notices" DROP COLUMN "displayEndAt"');
    await queryRunner.query('ALTER TABLE "notices" DROP COLUMN "displayStartAt"');
    await queryRunner.query('ALTER TABLE "notices" DROP COLUMN "isPublic"');
    await queryRunner.query('ALTER TABLE "notices" DROP COLUMN "isNotice"');

    await queryRunner.query('DROP INDEX "public"."IDX_inquiries_deletedAt"');
    await queryRunner.query('ALTER TABLE "inquiries" DROP COLUMN "deletedAt"');
  }
}
