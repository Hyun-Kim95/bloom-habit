# HabitFable 로컬 실행 가이드

이 문서는 로컬 개발 환경에서 HabitFable 프로젝트를 실행하는 기본 절차를 정리합니다.

## 1) API 서버 실행

앱/관리자 웹이 서버를 사용하므로 먼저 실행합니다.

```bash
cd server
npm install
npm run start:dev
```

- 기본 주소: `http://localhost:3000`
- 주요 환경 변수(선택): `JWT_SECRET`, `ADMIN_JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `OPENAI_API_KEY`

## 2) Flutter 앱 실행

저장소 루트(Flutter `pubspec.yaml`이 있는 디렉터리)에서 실행합니다.

```bash
flutter pub get
flutter run
```

- Android에서 `isar_flutter_libs` namespace 오류가 나면 한 번 실행:

```powershell
.\scripts\patch_isar_android.ps1
```

## 3) 관리자 웹 실행

```bash
cd admin
npm install
npm run dev
```

- 기본 주소: `http://localhost:5173`
- API 주소를 바꾸려면 `admin/.env`에서 `VITE_API_BASE` 값을 수정합니다.

## 4) Android 배포 번들(AAB) 빌드

Google Play 업로드용 번들은 저장소 루트에서 생성합니다.

**PostHog OFF (기본):**

```powershell
flutter build appbundle
# 또는
.\scripts\build_aab_release.ps1
```

**PostHog ON (비공개 테스트 등):** `android/local.properties`에 `ANALYTICS_ENABLED=true`, `POSTHOG_API_KEY=...` 설정 후:

```powershell
.\scripts\build_aab_prelaunch.ps1
```

Gradle이 `local.properties` → `--dart-define`을 자동 주입합니다. 상세: `docs/guides/posthog-local-test.md`

- 출력: `build/app/outputs/bundle/release/app-release.aab`
- Play 업로드 전 `pubspec.yaml`의 `version`(+buildNumber)이 이전보다 큰지 확인

## 5) PostHog (선택)

기본 빌드는 분석 OFF. `local.properties` + `scripts/build_aab_prelaunch.ps1` 또는 `scripts/build_apk_analytics.ps1` — `docs/guides/posthog-local-test.md`

