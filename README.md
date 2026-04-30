# HabitFable

`HabitFable`은 사용자의 습관 생성, 기록, 통계를 지원하는 서비스입니다.
프로젝트는 Flutter 앱, NestJS API 서버, React 기반 관리자 웹으로 구성되어 있습니다.

## 구성

- `lib/`: Flutter 앱 코드
- `server/`: NestJS API 서버
- `admin/`: 관리자 웹(Vite + React)
- `docs/`: 프로젝트 문서

## 문서

- 가이드 인덱스: `docs/guides/README.md`
- 실행 방법: `docs/guides/local-run.md`
- 기기 테스트: `docs/guides/flutter-device-testing.md`
- API/ERD 명세: `docs/spec/05-erd-api-spec.md`
- 계정/보관 정책: `docs/spec/04-account-policy.md`
- 변경 이력: `docs/CHANGELOG.md`

## 스크린샷 모드

- UI 캡처 시 디버그 배너와 하단 광고 배너를 숨기려면 아래처럼 실행합니다.
  - `flutter run --dart-define=SCREENSHOT_MODE=true`
- 플래그 미지정 시 기존 동작(디버그 배너/광고 정책)을 유지합니다.

## 관리자 공지 운영 정책

- 공지 생성/수정 시 아래 필드를 함께 설정합니다.
  - `공지여부(isNotice)`
  - `공개여부(isPublic)`
  - `개시기간(displayStartAt ~ displayEndAt)`
- 앱 노출은 `isNotice=Y`, `isPublic=Y`, `publishedAt<=현재`, 그리고 개시기간 범위 내일 때만 됩니다.
