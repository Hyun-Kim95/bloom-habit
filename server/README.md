# Bloom Habit API Server (NestJS)

## 실행

```bash
npm install
npm run start:dev
```

기본 포트: **3000**

## 엔드포인트 (1차)

- `POST /auth/google` — Body: `{ "idToken": "..." }` → accessToken, user 반환
- `POST /auth/apple` — Body: `{ "identityToken", "email?", "displayName?" }` → accessToken, user 반환
- `POST /auth/logout` — 로그아웃 (현재 no-op)
- `GET /sync?since=ISO8601` — 동기화 풀 (현재 빈 배열 반환)

## 인증 (1차)

- Google/Apple **토큰 검증 없이** idToken/identityToken 해시로 사용자 식별 후 JWT 발급.
- 프로덕션에서는 `google-auth-library`, Apple JWKS 검증 추가 필요.
- JWT 서명: `JWT_SECRET` 환경 변수 또는 기본값 사용.

## CORS

개발용으로 `origin: true` 설정. 프로덕션에서는 허용 origin 제한 필요.

## 관리자 API (prefix: `/admin`)

- `POST /admin/auth/login` — Body: `{ "email", "password" }` → `{ accessToken }`
  - 기본 계정: `admin@bloom.local` / `admin123` (환경 변수 `ADMIN_EMAIL`, `ADMIN_PASSWORD`로 변경 가능)
- `GET /admin/users` — 회원 목록 (Bearer 토큰 필요)
- `GET /admin/stats` — 대시보드 통계 (totalUsers, totalHabits, totalRecords)
- `GET/POST/PATCH/DELETE /admin/habit-templates` — 습관 템플릿
- `GET/POST/PATCH/DELETE /admin/notices` — 공지
- `GET/PATCH /admin/system-config` — 시스템 설정 (예: ai_fallback_messages)

관리자 JWT는 `ADMIN_JWT_SECRET` 환경 변수로 서명 (기본값: bloom-habit-admin-secret).

## AI 코멘트

- `POST /habits/:habitId/records/:recordId/ai-feedback` — 기록 완료 후 AI 격려 문구 요청 (Bearer 토큰 필요).
  - 응답: `{ response_text: string }`
  - 제한: 일 30회/사용자, (user, habit, date)당 1회. 초과 시 fallback 문구 반환.
- `OPENAI_API_KEY`가 있으면 OpenAI(gpt-4o-mini) 호출, 없으면 fallback 문구만 반환.
