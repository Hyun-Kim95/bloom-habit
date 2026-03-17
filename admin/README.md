# Bloom Habit 관리자 웹

## 실행

```bash
npm install
npm run dev
```

브라우저에서 `http://localhost:5173` (또는 Vite가 안내하는 주소)로 접속.

## 환경 변수

- `VITE_API_BASE` — API 서버 URL (기본: `http://localhost:3000`)

`.env` 예시:

```
VITE_API_BASE=http://localhost:3000
```

## 로그인

- 기본 계정: **admin@bloom.local** / **admin123**
- 서버의 `ADMIN_EMAIL`, `ADMIN_PASSWORD`로 변경 가능.

## 메뉴

- **대시보드** — 가입 회원 수, 전체 습관 수, 전체 기록 수
- **회원 관리** — 앱 가입 사용자 목록
- **습관 템플릿** — 템플릿 추가/삭제
- **공지 관리** — 공지 추가/삭제
- **AI 문구 / 설정** — AI fallback 문구 편집

API 서버(`server`)가 `http://localhost:3000`에서 실행 중이어야 합니다.
