import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissedHabitPushLocalTime1777600000000 implements MigrationInterface {
  name = 'AddMissedHabitPushLocalTime1777600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD "missedHabitPushLocalHour" smallint`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "missedHabitPushLocalMinute" smallint`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "missedHabitPushLocalMinute"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "missedHabitPushLocalHour"`);
  }
}
