import { MigrationInterface, QueryRunner } from "typeorm";

export class AddHabitUnit1777301000000 implements MigrationInterface {
    name = 'AddHabitUnit1777301000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "habits" ADD "unit" character varying`);
        await queryRunner.query(`ALTER TABLE "habit_templates" ADD "unit" character varying`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "habit_templates" DROP COLUMN "unit"`);
        await queryRunner.query(`ALTER TABLE "habits" DROP COLUMN "unit"`);
    }
}

