-- synchronize=false 프로덕션: 공지·습관 템플릿 영문 컬럼 추가
-- PostgreSQL

ALTER TABLE notices
  ADD COLUMN IF NOT EXISTS "titleEn" text,
  ADD COLUMN IF NOT EXISTS "bodyEn" text;

ALTER TABLE habit_templates
  ADD COLUMN IF NOT EXISTS "nameEn" character varying,
  ADD COLUMN IF NOT EXISTS "categoryEn" character varying;
