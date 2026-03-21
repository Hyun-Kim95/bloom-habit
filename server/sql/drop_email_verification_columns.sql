-- 프로덕션 등 synchronize=false 인 경우, 엔티티에서 제거된 컬럼을 DB에 반영할 때 실행.
-- TypeORM 기본 컬럼명(camelCase) 기준. 실제 DB 스키마에 맞게 조정하세요.

ALTER TABLE users DROP COLUMN IF EXISTS "pendingEmail";
ALTER TABLE users DROP COLUMN IF EXISTS "emailVerificationCodeHash";
ALTER TABLE users DROP COLUMN IF EXISTS "emailVerificationExpiresAt";
