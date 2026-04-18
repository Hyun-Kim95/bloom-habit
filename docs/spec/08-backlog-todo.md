# 백로그 / TODO — 관리자 페이지 (PRD J 기준)

**PRD J. 관리자 페이지**

- **목적**: 운영자가 서비스 핵심 데이터를 조회/관리할 수 있도록 한다.
- **상세 요구사항**: 관리자 로그인, 회원 조회, 습관 템플릿, 공지/운영 콘텐츠, AI 문구·프롬프트, 통계 대시보드, 설정값 관리 검토.

---

## 현재 상태

| 구분 | 상태 | 비고 |
|------|------|------|
| 관리자 **API** (서버) | ✅ 완료 | 로그인, 회원, 통계, 템플릿, 공지, system-config |
| 관리자 **페이지(UI)** | ✅ 완료 | `admin/` (Vite + React), 로그인·대시보드·회원·템플릿·공지·AI문구 |

**실행**: `cd admin` → `npm install` → `npm run dev` → 브라우저 `http://localhost:5173`. 서버는 `http://localhost:3000`에서 실행 중이어야 함.

---

## Todo 리스트 (관리자 페이지) — 완료 / 남은 항목

### 1. 기반

- [x] **1.1** 관리자 페이지 진입 경로 결정 (웹 전용 URL vs Flutter 웹/앱 내 숨김 메뉴) — **웹 전용** (`admin/` 배포 URL)
- [x] **1.2** 관리자 프론트 프로젝트 생성 (웹: React/Vue/HTML 등, 또는 Flutter web 라우트) — **Vite + React** (`admin/`)
- [x] **1.3** 관리자 API 클라이언트·인증 연동 (로그인 후 토큰 저장, 요청 시 Bearer 첨부) — `api.ts` 구현

### 2. 관리자 로그인

- [x] **2.1** 관리자 로그인 화면 UI (이메일, 비밀번호 입력)
- [x] **2.2** `POST /admin/auth/login` 호출 및 `accessToken` 저장
- [x] **2.3** 로그인 실패 시 에러 메시지 표시
- [x] **2.4** 로그인 성공 시 대시보드로 이동, 미로그인 시 로그인 페이지로 리다이렉트

### 3. 회원 조회 (기본 사용자 상태 확인)

- [x] **3.1** 회원 목록 화면 (테이블 또는 카드)
- [x] **3.2** `GET /admin/users` 연동 — id, email, displayName 등 표시
- [x] **3.3** 사용자 상태 표시/필터 — 상태 컬럼(연동/미연동), 필터(전체·이메일 연동·미연동), 검색(ID·이메일·표시명)

### 4. 습관 템플릿 등록 / 수정 / 삭제

- [x] **4.1** 습관 템플릿 목록 화면 (`GET /admin/habit-templates`)
- [x] **4.2** 템플릿 등록 폼 + `POST /admin/habit-templates` 연동
- [x] **4.3** 템플릿 수정 폼 + `PATCH /admin/habit-templates/:id` 연동
- [x] **4.4** 템플릿 삭제 + `DELETE /admin/habit-templates/:id` 연동 (확인 다이얼로그)

### 5. 공지 / 운영성 콘텐츠 관리

- [x] **5.1** 공지 목록 화면 (`GET /admin/notices`)
- [x] **5.2** 공지 등록 + `POST /admin/notices` (제목, 본문, publishedAt 등)
- [x] **5.3** 공지 수정 + `PATCH /admin/notices/:id`
- [x] **5.4** 공지 삭제 + `DELETE /admin/notices/:id`

### 6. AI 기본 문구 또는 프롬프트 관리

- [x] **6.1** 시스템 설정(또는 AI 문구) 화면 — `GET /admin/system-config` 연동
- [x] **6.2** AI fallback 문구 목록 조회·표시 (예: `ai_fallback_messages` JSON)
- [x] **6.3** fallback 문구 수정 UI + `PATCH /admin/system-config` 연동
- [ ] **6.4** (선택) 프롬프트 관리 — 서버에 프롬프트 설정 API가 있으면 해당 화면 추가

### 7. 기본 통계 대시보드

- [x] **7.1** 대시보드 레이아웃 (카드/섹션 구분)
- [x] **7.2** `GET /admin/stats` 연동 — totalUsers, totalHabits, totalRecords 표시
- [x] **7.3** 차트·추가 지표 — 기본 지표 막대 비교, 회원당 평균 습관 수, 습관당 평균 기록 수

### 8. 설정값 관리 가능 여부 검토

- [x] **8.1** “설정값 관리” 범위 정의 — `ai_fallback_messages`, `ai_daily_limit`, `app_jwt_expires_seconds` (문서·UI 반영)
- [x] **8.2** 검토 결과: 관리자 페이지에서 노출할 설정 목록 결정 — 위 3항목 + 추후 기능 플래그 등 확장 가능
- [x] **8.3** 설정 조회/수정 API·UI 구현 — 서버 `ConfigService`로 읽기, Auth/AI에서 사용. 관리자 화면에서 일일 AI 상한·JWT 만료(초) 입력·저장

### 9. 공통·마무리

- [x] **9.1** 관리자 전용 라우트 가드 (미로그인 시 로그인 페이지로)
- [x] **9.2** 로그아웃 기능
- [ ] **9.3** (선택) 반응형·접근성 점검

---

## 완료 요약

| 완료 | 항목 |
|------|--------|
| **완료** | 1.1~1.3, 2.1~2.4, 3.1~3.3, 4.1~4.4, 5.1~5.4, 6.1~6.3, 7.1~7.3, 8.1~8.3, 9.1~9.2 |
| **남은 항목** | 6.4 (선택·프롬프트 관리), 9.3 (선택·반응형·접근성) |

PRD J의 필수 요구사항 및 3.3, 7.3, 8.1~8.3까지 반영되었습니다.

---

## 진행 시 참고

- API 명세·curl 예시: [07-admin-api.md](07-admin-api.md)
- ERD·API 개요: [05-erd-api-spec.md](05-erd-api-spec.md) § 2.9 관리자
- 관리자 웹 실행: `admin/README.md`
