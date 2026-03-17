# Bloom Habit

습관 기록 앱 (Flutter) + API 서버 (NestJS) + 관리자 웹 (Vite + React).

---

## 1. API 서버 (NestJS) 실행

앱·관리자 웹이 이 서버에 연결하므로 **먼저 실행**하는 것이 좋습니다.

```bash
cd server
npm install
npm run start:dev
```

- **주소**: `http://localhost:3000`
- **환경 변수** (선택):
  - `JWT_SECRET` — 앱 JWT 서명 (기본값 있음)
  - `ADMIN_JWT_SECRET` — 관리자 JWT (기본: bloom-habit-admin-secret)
  - `ADMIN_EMAIL` / `ADMIN_PASSWORD` — 관리자 로그인 (기본: admin@bloom.local / admin123)
  - `OPENAI_API_KEY` — AI 코멘트용 (없으면 fallback 문구만 사용)

---

## 2. Flutter 앱 실행

모바일/웹 앱. 서버(`http://localhost:3000`)가 떠 있어야 로그인·동기화·AI 코멘트가 동작합니다.

```bash
# 프로젝트 루트(bloom_habit)에서 실행
flutter pub get
# Android 빌드 시 isar_flutter_libs namespace 오류가 나면 아래 패치 스크립트 실행 후 다시 빌드
# PowerShell: .\scripts\patch_isar_android.ps1
flutter run
```

- **Android 빌드 오류 (Namespace not specified)**: `isar_flutter_libs`가 AGP 8+에서 namespace를 요구합니다. `flutter pub get` 후 한 번만 실행하세요.
  ```powershell
  .\scripts\patch_isar_android.ps1
  ```
- **대상 선택**: 터미널에서 `flutter run` 시 기기/에뮬레이터 번호 선택 (예: Chrome, Windows, Android 에뮬레이터).
- **Android 에뮬레이터**: 앱에서 API는 자동으로 `http://10.0.2.2:3000` 사용 (호스트 PC 서버 연결).

---

## 3. 관리자 웹 실행

회원·통계·템플릿·공지·설정 관리. 서버가 `http://localhost:3000`에서 실행 중이어야 합니다.

```bash
cd admin
npm install
npm run dev
```

- **주소**: 브라우저에서 `http://localhost:5173` (Vite가 안내하는 주소)
- **로그인**: **admin@bloom.local** / **admin123**
- **API 주소 변경**: `.env`에 `VITE_API_BASE=http://localhost:3000` (또는 사용 중인 서버 URL)

---

## 실행 순서 요약

| 순서 | 대상        | 명령 (해당 폴더에서)     | 접속 주소           |
|------|-------------|---------------------------|---------------------|
| 1    | API 서버    | `npm run start:dev`       | http://localhost:3000 |
| 2    | Flutter 앱  | `flutter run`             | 기기/에뮬레이터     |
| 3    | 관리자 웹   | `npm run dev`             | http://localhost:5173 |

---

## 폴더 구조

- **루트** — Flutter 앱 (`lib/`, `pubspec.yaml`)
- **server/** — NestJS API (인증, 습관/기록, 동기화, 관리자, AI 코멘트)
- **admin/** — Vite + React + Tailwind 관리자 웹
- **docs/** — 정책·ERD·API 스펙 문서
