# Bloom Habit — 1단계 설계·정책 문서

1단계(정책 확정/설계) 산출물 모음입니다.

**위치:** 번호·도메인 스펙은 [`spec/`](spec/) 폴더, 클라이언트 연동·환경 가이드는 [`guides/`](guides/) 폴더에 둡니다.

| 문서 | 설명 |
|------|------|
| [01-statistics-level-formula.md](spec/01-statistics-level-formula.md) | 통계·레벨업 산식 (달성률, 연속 달성, 히트맵, 포인트/레벨) |
| [02-sync-policy.md](spec/02-sync-policy.md) | 동기화 정책 (시점, 방향, 충돌 해결) |
| [03-ai-policy.md](spec/03-ai-policy.md) | AI 코멘트 (저장 여부, 호출 제한, fallback) |
| [04-account-policy.md](spec/04-account-policy.md) | 비회원 모드, 탈퇴 후 보관, 계정 통합 |
| [05-erd-api-spec.md](spec/05-erd-api-spec.md) | ERD 엔티티 정의 및 API 명세 초안 |
| [06-database-setup.md](spec/06-database-setup.md) | 서버 DB 연동 (PostgreSQL) — 사용자 할 일 |
| [07-admin-api.md](spec/07-admin-api.md) | 관리자 API 사용 방법 (로그인·엔드포인트) |
| [08-backlog-todo.md](spec/08-backlog-todo.md) | 백로그/TODO (관리자 페이지 등 문서 대비 미구현 항목) |
| [09-prd-vs-current-gap.md](spec/09-prd-vs-current-gap.md) | PRD 대비 앱·서버·관리자 구현 갭 분석 |
| [10-prd-todo-list.md](spec/10-prd-todo-list.md) | 갭 기준 우선순위 작업 TODO (체크리스트) |
| [11-monetization-admob-iap.md](spec/11-monetization-admob-iap.md) | AdMob 배너 + 인앱 결제(광고 제거·후원) 설정·상품 ID |

**클라이언트 연동 참고:** [Google 로그인 SHA-1](guides/google-signin-setup.md) · [카카오 Android 키 해시](guides/kakao-android-keyhash.md)

---

## 워크플로·에이전트 산출물 매핑 (저장소 관례)

별도 `prd.md`, `gate-checklist.md` 파일은 두지 않고, 아래를 기준으로 한다.

| 단계 / 산출 | 사용 문서 |
|-------------|-----------|
| 요구·갭·범위·TODO | `spec/09-prd-vs-current-gap.md`, `spec/10-prd-todo-list.md` |
| API·ERD·동기·관리자 API | `spec/05-erd-api-spec.md`, 필요 시 `spec/07-admin-api.md`, `spec/02-sync-policy.md` |
| DB·마이그레이션 | `spec/06-database-setup.md` |
| 도메인 정책 | `spec/01`~`04` 번 문서, `spec/08-backlog-todo.md` |
| 리서치 | 해당 주제와 맞는 기존 `spec/NN-*.md` 보강, 또는 새 파일을 `spec/NN-제목.md`로 추가 후 **이 표에 행 추가** |
| UI (별도 단일 ui-spec 없음) | Flutter: `lib/`, `lib/l10n/`, `lib/core/theme/` · 관리자 웹: `admin/` · 요구 반영은 09·10 갱신 |
| 게이트 완료 판단 | `spec/10-prd-todo-list.md`·`spec/08-backlog-todo.md` 관련 항목, 루트 `README.md` 실행·검증, `reports/test-report.md`·`reports/review.md` |
| 테스트·리뷰·릴리즈 요약 | 저장소 루트 `reports/test-report.md`, `reports/review.md`, `reports/release-note.md` (없으면 생성) |

**작성일:** 2026-03-17  
**버전:** 초안 (개발 중 협의·조정 가능)

---

**도구 환경:** Cursor 훅(`.cursor/hooks.json`)과 Git `post-commit`(옵시디언 동기화)은 **PowerShell 7(`pwsh`)**이 PATH에 있어야 한다. Windows PowerShell 5.1만 있는 환경에서는 [PowerShell 7 설치](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) 후 `pwsh`를 사용한다.
