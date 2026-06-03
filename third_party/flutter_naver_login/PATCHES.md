# HabitFable patches (flutter_naver_login 2.1.1)

Upstream: `flutter_naver_login` on pub.dev.

## Dependency

- `com.navercorp.nid:oauth` **5.10.0** (플러그인 Kotlin API와 호환; 5.11.x 는 `NidOAuthCallback` 등 breaking change)

## Changes

1. **Android `FlutterNaverLoginPlugin.login`**
   - Removed automatic `logout()` before each `authenticate()` call.
   - Reason: after OAuth succeeds but profile fetch fails, retry forced full consent every time.

2. **Android `jsonObjectToMap`**
   - Parse non-string JSON fields (e.g. numeric `id`) without throwing.

App-side session cleanup: `AuthRepository._clearNaverSdkSession()` on failed server exchange only.
