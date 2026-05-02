import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUserIanaTimeZone1777500000000 implements MigrationInterface {
  name = 'AddUserIanaTimeZone1777500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD "ianaTimeZone" character varying(64)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "ianaTimeZone"`);
  }
}
