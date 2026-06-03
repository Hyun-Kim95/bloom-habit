# 네이버 로그인 (Android) — 설정·오류

## 네이버 개발자 센터에 SHA-1은 없음

네이버 로그인은 **카카오·Google·Firebase처럼 SHA-1을 콘솔에 등록하지 않습니다.**  
(이전 앱 안내에 SHA-1을 넣은 것은 잘못된 설명이었습니다.)

등록·확인 항목은 아래만 해당합니다.

## 1. 네이버 개발자 센터

[developers.naver.com](https://developers.naver.com/apps/) → **내 애플리케이션** → 해당 앱

| 확인 | 내용 |
|------|------|
| API | **네이버 로그인** 사용 설정 |
| Android 환경 | **안드로이드 앱 패키지 이름** = `com.khyun.bloom_habit` (오타·공백 없이) |
| 다운로드 URL | Play 스토어 URL 또는 임시 URL (검수용) |
| Client ID / Secret | 아래 `local.properties` 값과 **완전히 동일** |

## 2. 앱 빌드 (`android/local.properties`)

gitignore 파일. AAB/릴리즈 빌드 시 이 값이 없으면 로그인 키가 비어 들어갑니다.

```properties
NAVER_CLIENT_ID=...
NAVER_CLIENT_SECRET=...
NAVER_CLIENT_NAME=HabitFable
```

`NAVER_CLIENT_NAME`은 개발자 센터에 보이는 **애플리케이션 이름**과 맞추는 것이 좋습니다.

## 3. 새 APK를 깔았는데도 실패할 때

콘솔·`local.properties` 가 맞아도 **릴리즈 APK(`flutter build apk --release`)** 에서만 실패하면 대부분 **R8(코드 축소)** 입니다.

### A. 화면에 붙는 코드 확인

로그인 실패 문구 끝에 `(errorCode:…)` 가 붙습니다. 예:

- `ERROR_NO_CATAGORIZED` / `no_catagorized` → ProGuard·SDK 내부 오류
- `CLIENT_ERROR_CERTIFICATION_ERROR` → 기기 SSL/인증서
- `CLIENT_ERROR_NO_CLIENTID` → 빌드에 키 미포함

### B. `no_catagorized_error` 와 릴리즈 minify

이 오류는 **릴리즈 R8(코드 축소)** 에서 네이버 SDK가 깨질 때 나옵니다.

**기본 설정(2026-06):** 릴리즈 빌드는 `isMinifyEnabled = false` 로 APK를 맞춥니다.  
`flutter build apk --release` 만으로 다시 설치하면 됩니다.

minify를 다시 켜 실험하려면 `local.properties` 에 `RELEASE_ENABLE_MINIFY=true` (고급).

## 4. 릴리즈(Play)에서만 실패할 때

디버그(`flutter run`)는 되고 **스토어 설치본만 실패**하면:

- **R8(ProGuard)**: `android/app/proguard-rules.pro`의 `com.navercorp.nid.**` keep
- **SDK 버전**: `third_party/flutter_naver_login` → Naver OAuth **5.10.0** (플러그인 호환)
- 수정 반영 후 **새 AAB**로 재설치

`no_categorized` / `no_catagorized_error` 는 위 조합에서 자주 보고됩니다.

## 5. SHA-1 스크립트는?

`scripts/print-android-signing-sha.ps1` 은 **Firebase·Google 로그인** 등록용입니다.  
**네이버 콘솔에는 넣을 곳이 없습니다.**

## 6. 코드 쪽 (이 레포)

- `third_party/flutter_naver_login`: 로그인 전 `logout()` 제거, SDK 5.11.2
- `AuthRepository`: SDK 세션 재사용, 오류 코드별 메시지
