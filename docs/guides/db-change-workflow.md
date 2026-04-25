# DB Change Workflow

DB 스키마 변경을 코드 리뷰 가능하고 재현 가능한 절차로 관리하기 위한 팀 규칙.

## 원칙

- 스키마 변경은 항상 `migration` 파일로 관리한다.
- 운영 환경에서 엔티티 자동 동기화(`synchronize`)를 사용하지 않는다.
- 변경 이력은 Git 커밋으로 추적 가능해야 한다.

## 변경 절차

1. 엔티티 변경
2. 마이그레이션 생성
   - `npm run migration:generate -- src/migrations/<Name>`
3. 생성 파일 검토
   - `up`/`down`이 의도와 일치하는지
   - 예상치 못한 `DROP`/대규모 `ALTER` 없는지
4. 로컬 적용 검증
   - `npm run build`
   - `npm run migration:run`
   - 앱/API smoke test
5. 커밋/푸시/PR
6. 배포 환경 적용
   - `npm run migration:run && npm run start:prod`

## 권장 네이밍

- 생성명은 변경 의도를 드러내게 작성
  - 예: `AddLegalLocaleIndex`, `CreateInquiryStatusHistory`

## 리뷰 체크포인트

- 데이터 손실 가능 쿼리 여부
- nullability/기본값 변경 영향
- 인덱스 추가/삭제 영향
- 롤백(`down`) 가능 여부

## 예외 상황

자동 생성으로 안전한 쿼리를 얻기 어려운 경우:

1. 빈 마이그레이션 생성
   - `npm run migration:create -- src/migrations/<Name>`
2. 수동으로 `up`/`down` 작성
3. 로컬 검증 후 PR

## 배포 전 최소 점검

- [ ] 대상 환경 `DATABASE_URL` 확인
- [ ] baseline 동기화 필요 여부 (`--fake`) 확인
- [ ] 최근 migration 파일 누락 없는지 확인
