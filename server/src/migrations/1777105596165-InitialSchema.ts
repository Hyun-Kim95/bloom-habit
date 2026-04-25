import { MigrationInterface, QueryRunner } from "typeorm";

export class InitialSchema1777105596165 implements MigrationInterface {
    name = 'InitialSchema1777105596165'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "users" ("id" character varying NOT NULL, "email" character varying, "emailVerifiedAt" TIMESTAMP WITH TIME ZONE, "authProvider" character varying(20), "displayName" character varying, "avatarUrl" character varying(2048), "fcmToken" character varying(512), "isActive" boolean NOT NULL DEFAULT true, "deactivatedAt" TIMESTAMP WITH TIME ZONE, "deactivationReason" character varying(500), "deactivatedBy" character varying(20), "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "habits" ("id" character varying NOT NULL, "userId" character varying NOT NULL, "name" character varying NOT NULL, "category" character varying, "goalType" character varying NOT NULL DEFAULT 'completion', "goalValue" integer, "startDate" character varying NOT NULL, "colorHex" character varying, "iconName" character varying, "archivedAt" TIMESTAMP WITH TIME ZONE, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_b3ec33c2d7af69d09fcf4af7e39" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "habit_records" ("id" character varying NOT NULL, "habitId" character varying NOT NULL, "recordDate" character varying NOT NULL, "value" integer, "completed" boolean NOT NULL DEFAULT false, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_23ff1af219e2213938f63c2d3fd" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "admin_users" ("id" character varying NOT NULL, "email" character varying NOT NULL, "passwordHash" character varying NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_dcd0c8a4b10af9c986e510b9ecc" UNIQUE ("email"), CONSTRAINT "PK_06744d221bb6145dc61e5dc441d" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "habit_templates" ("id" character varying NOT NULL, "name" character varying NOT NULL, "nameEn" character varying, "category" character varying, "categoryEn" character varying, "goalType" character varying NOT NULL DEFAULT 'completion', "goalValue" double precision, "colorHex" character varying, "iconName" character varying, "isActive" boolean NOT NULL DEFAULT true, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_1bd824066c6ae4731e72e28efcf" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "notices" ("id" character varying NOT NULL, "title" character varying NOT NULL, "body" text NOT NULL, "titleEn" text, "bodyEn" text, "publishedAt" TIMESTAMP WITH TIME ZONE, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_3eb18c29da25d6935fcbe584237" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "system_config" ("key" character varying NOT NULL, "value" text NOT NULL, "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_eedd3cd0f227c7fb5eff2204e93" PRIMARY KEY ("key"))`);
        await queryRunner.query(`CREATE TABLE "inquiries" ("id" character varying NOT NULL, "userId" character varying NOT NULL, "subject" character varying NOT NULL, "body" text NOT NULL, "status" character varying NOT NULL DEFAULT 'pending', "adminReply" text, "repliedAt" TIMESTAMP WITH TIME ZONE, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_ceacaa439988b25eb9459e694d9" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "legal_documents" ("id" character varying NOT NULL, "type" character varying(20) NOT NULL, "locale" character varying(5) NOT NULL DEFAULT 'ko', "version" integer NOT NULL DEFAULT '1', "title" character varying(255) NOT NULL DEFAULT '', "content" text NOT NULL DEFAULT '', "effectiveFrom" date, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_846b11262368906ded5d26ac271" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "missed_habit_push_logs" ("id" SERIAL NOT NULL, "userId" character varying NOT NULL, "pushDate" character varying NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_4ebe7ab11e4cfe79b557b5fbd8e" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE UNIQUE INDEX "IDX_628033845ac1a13c6fca32ed69" ON "missed_habit_push_logs" ("userId", "pushDate") `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_628033845ac1a13c6fca32ed69"`);
        await queryRunner.query(`DROP TABLE "missed_habit_push_logs"`);
        await queryRunner.query(`DROP TABLE "legal_documents"`);
        await queryRunner.query(`DROP TABLE "inquiries"`);
        await queryRunner.query(`DROP TABLE "system_config"`);
        await queryRunner.query(`DROP TABLE "notices"`);
        await queryRunner.query(`DROP TABLE "habit_templates"`);
        await queryRunner.query(`DROP TABLE "admin_users"`);
        await queryRunner.query(`DROP TABLE "habit_records"`);
        await queryRunner.query(`DROP TABLE "habits"`);
        await queryRunner.query(`DROP TABLE "users"`);
    }

}
