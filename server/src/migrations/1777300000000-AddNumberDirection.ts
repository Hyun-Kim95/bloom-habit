import { MigrationInterface, QueryRunner } from "typeorm";

export class AddNumberDirection1777300000000 implements MigrationInterface {
    name = 'AddNumberDirection1777300000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "habits" ADD "numberDirection" character varying NOT NULL DEFAULT 'gte'`);
        await queryRunner.query(`ALTER TABLE "habit_templates" ADD "numberDirection" character varying NOT NULL DEFAULT 'gte'`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "habit_templates" DROP COLUMN "numberDirection"`);
        await queryRunner.query(`ALTER TABLE "habits" DROP COLUMN "numberDirection"`);
    }

}
