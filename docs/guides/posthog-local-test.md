# PostHog 로컬·Play 빌드 가이드

HabitFable의 PostHog 연동은 **기본 OFF**입니다. `android/local.properties`(gitignore)에 키를 넣으면 Gradle이 `--dart-define`을 **자동 주입**합니다.

## 안전 장치

| 조건 | 동작 |
|------|------|
| `ANALYTICS_ENABLED` 없음 / `false` | PostHog **no-op** |
| `POSTHOG_API_KEY` 없음 | enabled여도 no-op |
| `local.properties` | **Git 커밋 금지** (키·토큰 보관용) |

## 1) local.properties 설정 (한 번만)

`android/local.properties.example`을 참고해 **본인 PC**의 `android/local.properties`에 추가:

```properties
ANALYTICS_ENABLED=true
POSTHOG_API_KEY=phc_YOUR_TOKEN
POSTHOG_HOST=https://us.i.posthog.com
ANALYTICS_ENVIRONMENT=prelaunch
```

- Host 기본값: `https://us.i.posthog.com` (생략 가능)
- `ANALYTICS_ENVIRONMENT`: 비공개 테스트 `prelaunch`, 정식 오픈 `production`

분석 **OFF** Play AAB가 필요하면 위 네 줄을 **제거**하거나 `ANALYTICS_ENABLED=false`로 두세요.

## 2) 빌드 명령 (짧게)

저장소 루트에서:

| 목적 | 명령 |
|------|------|
| **비공개 테스트 AAB** (PostHog ON) | `.\scripts\build_aab_prelaunch.ps1` |
| **Play AAB** (PostHog OFF) | `.\scripts\build_aab_release.ps1` 또는 `flutter build appbundle` |
| **본인 폰 APK** (PostHog ON) | `.\scripts\build_apk_analytics.ps1` |

스크립트 없이 직접 빌드해도 됩니다. `local.properties`가 설정돼 있으면:

```powershell
flutter build appbundle
```

Gradle(`android/app/build.gradle.kts`)이 `API_BASE_URL`, PostHog define을 합쳐 넣습니다.

수동 `--dart-define=...`는 스크립트/local.properties 없이 **일회성** 빌드할 때만 사용하면 됩니다.

## PostHog Live events 확인

PostHog → **Activity** / **Live events**:

| 순서 | 앱 동작 | 기대 이벤트 |
|------|---------|-------------|
| 1 | 앱 cold start | `app_opened` |
| 2 | 온보딩 완료 | `onboarding_completed` |
| 3 | 소셜 로그인 성공 | `login_success` |
| 4 | 습관 생성 | `habit_created` |
| 5 | 습관 체크 | `habit_completed` |
| 6 | 알림 권한 | `notification_permission_result` |

공통 속성: `environment=prelaunch`, `platform=android`, `app_version`, `build_number`

## no-op 검증

`local.properties`에서 PostHog 줄을 제거(또는 `ANALYTICS_ENABLED=false`) 후:

```powershell
flutter build apk --release
```

설치 후 Live events **0건**이면 정상.

## Play 비공개 테스트 (시행일 2026-05-31)

1. `local.properties`에 PostHog 설정 + `ANALYTICS_ENVIRONMENT=prelaunch`
2. `.\scripts\build_aab_prelaunch.ps1` → AAB 보관
3. **5월 31일** Play 비공개 테스트 트랙 업로드 (그 전 업로드 시 테스터에게 즉시 수집 시작)
4. Play **데이터 안전** 설문 PostHog 반영

출력: `build/app/outputs/bundle/release/app-release.aab`

## 정식 오픈 시

- `ANALYTICS_ENVIRONMENT=production`
- `.\scripts\build_aab_prelaunch.ps1` (또는 `flutter build appbundle`)
- PostHog Session Replay는 초기 **OFF** 권장

## 관련 문서

- 로컬 실행: `docs/guides/local-run.md`
- Play 법률 URL: `docs/guides/play-console-legal-url.md`
