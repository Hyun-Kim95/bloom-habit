# DB Migration Troubleshooting

마이그레이션 적용 중 자주 발생하는 오류와 대응 가이드.

## 1) `relation "<table>" does not exist`

### 증상

- 서버 기동 시 특정 테이블 조회에서 즉시 크래시
- 예: `relation "system_config" does not exist`

### 원인

- 프로덕션에서 `synchronize`가 꺼진 상태
- DB에 필요한 테이블이 아직 없음

### 대응

1. 마이그레이션 파일 준비 확인
2. `npm run migration:run` 실행
3. 이미 테이블이 있는 기존 DB면 baseline에 한해 `--fake` 적용

## 2) `ERR_REQUIRE_ESM` (`uuid` 관련)

### 증상

- `require() of ES Module ... uuid ... not supported`

### 원인

- CommonJS 런타임에서 ESM 전용 패키지 버전 사용

### 대응

- `uuid`를 CJS 호환 버전으로 고정
- lockfile 업데이트 후 재배포

## 3) `No changes in database schema were found`

### 의미

- 현재 DB와 엔티티 차이가 없어 generate할 마이그레이션이 없음

### 대응

- 엔티티 변경 여부 확인
- baseline 생성 목적이라면 빈 DB로 연결 후 다시 generate

## 4) 인증/연결 오류 (`28P01`, timeout 등)

### 원인

- `DATABASE_URL` 오입력
- 대상 DB/네트워크 접근 불가

### 대응

1. Railway Variables 값 재확인
2. 올바른 환경(로컬/스테이징/운영)인지 확인
3. 재배포 후 로그 재확인

## 운영 로그 확인 포인트

- `migration:run` 단계 성공 여부
- 서버 listen 로그 출력 여부
- 반복 재시작(crash loop) 여부

## 최종 확인

- [ ] `migration:show` 상태 정상
- [ ] 핵심 API (`/admin/auth/login` 등) 응답 정상
- [ ] 앱/관리자 화면에서 DB 읽기/쓰기 정상
