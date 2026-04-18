# Android 구글 로그인 설정

## A. ApiException: 10 (DEVELOPER_ERROR)

에뮬레이터/기기에서 **PlatformException(sign_in_failed, ApiException: 10)** 이 나오면, Google Cloud에 앱의 **패키지명**과 **SHA-1**이 등록되지 않은 상태입니다.

## B. ID token 없음

**"ID token 없음"** 이 나오면, **웹 애플리케이션** OAuth 클라이언트 ID를 앱에 설정하지 않은 상태입니다. 아래 "2. 웹 클라이언트 ID (ID 토큰용)"을 진행한 뒤, 앱의 `kGoogleServerClientId` 값을 넣어 주세요.

---

## 1. 앱 정보 확인

- **패키지명**: `com.example.bloom_habit`  
  (변경했다면 `android/app/build.gradle.kts`의 `applicationId` 확인)

- **디버그 SHA-1** (에뮬레이터/디버그 빌드용):  
  PC에서 아래 명령으로 확인한 값을 사용합니다.

### Windows (PowerShell)

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력에서 **SHA1:** 뒤의 값(예: `F8:69:CB:36:...`)을 복사합니다.

### macOS / Linux

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 2. Google Cloud Console 설정

### 2-1. Android 클라이언트 (필수)

1. [Google Cloud Console](https://console.cloud.google.com/) 접속 후 프로젝트 선택(또는 새 프로젝트 생성).
2. **API 및 서비스** → **사용자 인증 정보** → **+ 사용자 인증 정보 만들기** → **OAuth 클라이언트 ID**.
3. **애플리케이션 유형**: **Android** 선택.
4. 입력:
   - **이름**: 예) Bloom Habit Android
   - **패키지 이름**: `com.example.bloom_habit`
   - **SHA-1 인증서 지문**: 위에서 복사한 SHA-1 (콜론 포함, 한 줄)
5. **만들기** 클릭.

### 2-2. 웹 클라이언트 ID (ID 토큰용, 필수)

Android에서 **idToken**을 받아 서버로 보내려면, 같은 프로젝트에 **웹 애플리케이션** 클라이언트가 있어야 합니다.

1. **사용자 인증 정보** → **+ 사용자 인증 정보 만들기** → **OAuth 클라이언트 ID**.
2. **애플리케이션 유형**: **웹 애플리케이션** 선택.
3. **이름**: 예) Bloom Habit Web
4. **만들기** 클릭 후 나온 **클라이언트 ID** (예: `123456789-xxx.apps.googleusercontent.com`) 복사.
5. 앱 코드에 넣기: `lib/core/router/app_providers.dart` 에서  
   `kGoogleServerClientId` 값을 위에서 복사한 **클라이언트 ID**로 바꿉니다.  
   예: `const String kGoogleServerClientId = '123456789-xxx.apps.googleusercontent.com';`

---

## 3. OAuth 동의 화면

처음이면 **OAuth 동의 화면**에서 앱 이름·지원 이메일 등을 채우고 **테스트 사용자**에 로그인할 구글 계정을 추가해야 할 수 있습니다.

---

## 4. 적용 후

- 설정 반영에 1~2분 걸릴 수 있습니다.
- 앱을 완전히 종료했다가 다시 실행한 뒤 구글 로그인을 다시 시도하세요.

---

## 5. 릴리스 빌드용

나중에 **릴리스 키**로 서명한 APK/AAB를 쓰면, 그 키스토어의 SHA-1도 Google Cloud에 **같은 패키지명**으로 추가해야 합니다.  
(디버그 SHA-1과 릴리스 SHA-1을 둘 다 등록해 두면 디버그/릴리스 모두 로그인 가능합니다.)
