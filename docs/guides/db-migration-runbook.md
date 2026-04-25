# DB Migration Runbook (Railway)

Railway 운영 환경에서 TypeORM 마이그레이션을 안전하게 적용하기 위한 실행 절차.

## 대상 범위

- `server/` (NestJS + TypeORM)
- Railway `server` 서비스 + Railway Postgres

## 사전 조건

- `server/src/database/data-source.ts`가 존재한다.
- `server/package.json`에 `migration:*` 스크립트가 존재한다.
- `DATABASE_URL`이 올바른 Postgres를 가리킨다.

## 분기 1: 신규 DB (테이블 없음)

1. 로컬 또는 CI에서 마이그레이션 파일 생성/검토/커밋
2. Railway 배포 시 아래 Start Command 사용
   - `npm run migration:run && npm run start:prod`
3. 로그에서 마이그레이션 성공 및 서버 기동 확인

## 분기 2: 기존 DB (이미 테이블 존재)

초기 baseline migration을 추가한 직후, 기존 DB에 같은 테이블을 다시 생성하면 충돌한다.

### 1회성 baseline 동기화

1. Railway `server` 서비스 Start Command를 임시 변경
   - `npm run migration:run -- --fake && npm run start:prod`
2. 배포 실행
3. 로그에서 실패 없이 기동 확인
4. Start Command를 운영 기본값으로 원복
   - `npm run migration:run && npm run start:prod`

## 운영 기본 절차 (권장)

1. 엔티티 변경
2. `npm run migration:generate -- src/migrations/<Name>`
3. 생성 파일 리뷰 (`up`/`down`, 위험 쿼리 확인)
4. 커밋/푸시
5. Railway 배포 (`migration:run` 자동 실행)
6. API smoke test

## 검증 체크리스트

- [ ] `migration:show`에서 기대한 상태인지 확인
- [ ] 로그에 `relation does not exist` 오류 없음
- [ ] 관리자 로그인/API 핵심 엔드포인트 정상
- [ ] 데이터 읽기/쓰기 정상

## 금지/주의

- 프로덕션에서 `synchronize`에 의존하지 않는다.
- baseline 이후 매 배포에 `--fake`를 반복 사용하지 않는다.
- 마이그레이션 검토 없이 운영 DB에 직접 스키마 변경하지 않는다.
