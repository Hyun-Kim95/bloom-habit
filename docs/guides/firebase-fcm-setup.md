# Firebase FCM 설정 가이드 (문의 답변 푸시 알림)

Firebase 프로젝트를 생성한 후, 아래 순서대로 진행하세요.

---

## 1. Firebase Console에서 앱 등록

### 1-1. Android 앱 추가

1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 선택
2. **프로젝트 개요** 옆 톱니바퀴 → **프로젝트 설정**
3. **일반** 탭에서 **앱** 섹션 → **Android 앱** 아이콘(로봇) 클릭
4. **Android 패키지 이름** 입력
  - 이 프로젝트: `com.khyun.bloom_habit` (또는 `android/app/build.gradle.kts`의 `applicationId`와 동일하게)
5. **앱 등록** 클릭
6. **google-services.json** 다운로드 버튼 클릭 → 파일 저장

### 1-2. google-services.json 넣기 (Flutter)

1. 다운로드한 `google-services.json`을 아래 경로에 복사:
  ```
   bloom_habit/android/app/google-services.json
  ```
2. **Windows**: `d:\cursor\flutter_test\bloom_habit\android\app\google-services.json`

### 1-3. Android 빌드 설정 (이미 적용됨)

이 프로젝트에는 이미 다음이 적용되어 있습니다.

- `android/settings.gradle.kts`: `id("com.google.gms.google-services") version "4.4.2" apply false`
- `android/app/build.gradle.kts`: `id("com.google.gms.google-services")` in plugins

**google-services.json**만 `android/app/` 아래에 두면 됩니다.

### 1-4. (선택) iOS 앱 추가

iOS도 푸시를 쓰려면:

1. Firebase Console **프로젝트 설정** → **iOS 앱** 추가
2. **번들 ID** 입력 (Xcode에서 확인, 예: `com.khyun.bloomHabit`)
3. **GoogleService-Info.plist** 다운로드
4. Flutter 프로젝트에서:
  ```
   bloom_habit/ios/Runner/GoogleService-Info.plist
  ```
   에 복사한 뒤, Xcode에서 **Runner** 타겟에 해당 파일이 포함되어 있는지 확인.

---

## 2. 서버용 서비스 계정 키 (Firebase Admin SDK)

관리자가 문의에 답변했을 때 서버에서 FCM으로 푸시를 보내려면 **서비스 계정 키**가 필요합니다.

### 2-1. 키 파일 만들기

1. Firebase Console → **프로젝트 설정** (톱니바퀴)
2. **서비스 계정** 탭 클릭
3. **Firebase Admin SDK** 섹션에서 **새 비공개 키 생성** 클릭 → **키 생성** 확인
4. JSON 파일이 다운로드됨 (예: `bloom-habit-xxxxx-firebase-adminsdk-xxxxx.json`)

### 2-2. 서버에 키 설정 (둘 중 하나만 하면 됨)

**방법 A: 파일 경로로 설정 (권장)**

1. 다운로드한 JSON 파일을 **서버가 실행되는 환경**에서 접근 가능한 폴더에 둔다.
  (로컬 개발이면 예: `d:\cursor\flutter_test\bloom_habit\server\keys\` 같은 폴더 생성 후 복사)
2. **절대 경로**를 복사한다.
  - Windows 예: `D:\cursor\flutter_test\bloom_habit\server\keys\bloom-habit-xxxxx-firebase-adminsdk-xxxxx.json`
3. 서버 `.env` 파일에 추가:
  ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=D:\cursor\flutter_test\bloom_habit\server\keys\bloom-habit-xxxxx-firebase-adminsdk-xxxxx.json
  ```
   (실제 파일명으로 바꾸고, 경로에 공백이 있으면 따옴표로 감싸도 됨)

**방법 B: JSON 내용을 환경 변수로**

1. 다운로드한 JSON 파일을 메모장 등으로 연다.
2. **한 줄로** 만든다 (줄바꿈 제거).
  - 예: `{"type":"service_account","project_id":"bloom-habit-xxxxx",...}`
3. `.env`에 추가 (한 줄):
  ```env
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"bloom-habit-xxxxx",...}
  ```
  - 주의: 값 안에 `"`가 많으므로, `.env`에서 따옴표 이스케이프 규칙을 확인하거나, JSON 전체를 작은따옴표로 감싸는 방식으로 저장.

### 2-3. 서버 재시작

- `.env` 수정 후 서버를 한 번 종료했다가 다시 실행한다.
- `npm run start:dev` 또는 `npm run dev` 등으로 실행 중이었다면 다시 실행.

---

## 3. 앱에서 확인할 것

### 3-1. 패키지/초기화

- `pubspec.yaml`에 이미 추가된 것:
  - `firebase_core`
  - `firebase_messaging`
- `main.dart`에서 `Firebase.initializeApp()` 호출되어 있음 (Firebase 미설정이어도 예외만 잡고 무시).

### 3-2. Android 최소 SDK

- FCM 사용을 위해 `android/app/build.gradle.kts`의 `minSdk`가 **21 이상**인지 확인 (보통 21 또는 24 사용).

### 3-3. 앱 실행 순서

1. **서버** 실행 (FIREBASE_SERVICE_ACCOUNT_PATH 또는 JSON 설정 후)
2. **앱** 실행 후 **로그인**
3. **홈** 한 번 들어오면, 그때 FCM 토큰이 서버 `PATCH /me`로 전송되어 DB에 저장됨
4. **관리자**에서 해당 사용자의 문의에 **답변** 입력 후 저장
5. 잠시 후 해당 사용자 **앱**에 푸시 알림 수신 확인

### 3-4. data-only 푸시와 표시 책임 (문의 답변·미달성 공통)

서버는 **Android에서 시스템이 자동으로 띄우는 FCM `notification` 블록을 쓰지 않고**, `data` 맵에 `type`, `title`, `body` 등(값은 모두 **문자열**)만 넣어 보냅니다. 이렇게 하면 Android 포그라운드에서 **OS 자동 알림 + 앱 로컬 알림**이 겹치지 않습니다.

- **Android**: `flutter_local_notifications`가 `data`를 읽어 **한 번만** 표시합니다. 미달성 푸시는 `data.imageUrl`의 이미지를 앱이 받아와 **Big Picture** 스타일로 붙이며, 실패 시 제목/본문만 표시합니다.
- **iOS**: 서버가 `apns.payload.aps.alert`로 시스템 알림을 띄우므로, 앱은 **이미 표시된 메시지**에 대해 로컬 알림을 **중복으로 띄우지 않습니다**. 포그라운드에서도 배너가 보이도록 앱에서 `setForegroundNotificationPresentationOptions`를 사용합니다.
- **백그라운드**: `firebaseMessagingBackgroundHandler`에서 동일한 `data` 파싱 규칙으로 Android 로컬 표시를 맞춥니다(핸들러에서 `Firebase.initializeApp()` 호출).

---

## 4. 문제 해결


| 현상                    | 확인할 것                                                                                                                                                                                                |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 앱 실행 시 Firebase 관련 에러 | `android/app/google-services.json` 존재 여부, 패키지명/번들ID가 Firebase에 등록한 것과 같은지                                                                                                                            |
| 푸시가 안 옴               | 1) 서버 `.env`에 FIREBASE_SERVICE_ACCOUNT_PATH 또는 JSON 설정했는지 2) 한 번 로그인 후 홈까지 들어와서 토큰이 등록됐는지 3) 관리자에서 **답변 내용을 입력하고 저장**했는지                                                                             |
| **문의 답변** 푸시만 안 옴     | 답변 **내용이 이전과 달라져야** 전송됨(동일 문구 재저장은 스킵). 서버 로그에 `inquiry_reply skipped: missing fcm token` / `firebase not initialized` / `send failed` 있는지 확인. 앱·서버가 **동일 Firebase 프로젝트**인지, iOS는 **APNs** 등록 여부 확인. |
| Android에서 문의·미달성 푸시가 안 보임 | 로컬 알림 채널 ID는 앱 `notification_service.dart`의 `_fcmChannelId`(`habit_fable_inquiry_reply`)로 고정됩니다. 서버는 data-only이므로 **채널은 앱 쪽 설정**이 표시에 사용됩니다. HTTP 이미지(Big Picture)는 기기에서 `PUBLIC_ASSET_BASE_URL` 등 **도달 가능한 URL**이어야 합니다. |
| 에뮬레이터에서 푸시 안 옴        | Google Play 서비스 있는 에뮬레이터 사용 또는 실제 기기에서 테스트                                                                                                                                                           |


---

## 5. 요약 체크리스트

- Firebase Console에서 Android 앱 등록, 패키지명 일치
- `android/app/google-services.json` 복사
- `android/build.gradle.kts`에 Google services classpath, `android/app/build.gradle.kts`에 `apply plugin: 'com.google.gms.google-services'`
- Firebase Console → 서비스 계정 → 새 비공개 키 생성 → JSON 다운로드
- 서버 `.env`에 `FIREBASE_SERVICE_ACCOUNT_PATH=절대경로` 또는 `FIREBASE_SERVICE_ACCOUNT_JSON=...` 설정
- 서버 재시작
- 앱 빌드 후 로그인 → 홈 진입 → 관리자에서 문의 답변 → 푸시 수신 확인

---

## 6. 미달성 습관 리마인더 (로컬 저녁 Big Picture 푸시)

오늘 완료하지 않은 습관이 있는 사용자에게 **해당 사용자 IANA 타임존 기준 매일 한 번**(기본 전송 창: 로컬 **23:00~23:15** 근처) 잠금 화면용 Big Picture 푸시가 발송됩니다.

### 6-1. 동작 요약

- 앱이 `PATCH /me`로 `**ianaTimeZone`**(예: `Asia/Seoul`)을 올리며, 비어 있으면 서버는 **`Asia/Seoul`**로 간주합니다.
- **틱 크론** (기본 `*/5 * * * `*, 환경변수 `MISSED_HABIT_TICK_CRON`): 주기마다 “전송 창 안에 있는 유저”만 검사합니다.
- 전송 창: `MISSED_HABIT_LOCAL_SEND_HOUR`(기본 23), `MISSED_HABIT_LOCAL_SEND_MINUTE`(기본 0), `MISSED_HABIT_SEND_WINDOW_MINUTES`(기본 15, **코드에서 최소 15분으로 클램프**) — 유저 **로컬 시각**이 `[H:M, H:M+window)` 안일 때만 후보. **전송 창을 크론 주기보다 짧게 두면 틱이 창을 건너뛰어 알림이 아예 안 나갈 수 있으므로**, 기본 조합은 창 ≥ 틱 간격을 만족하도록 맞춰 두었습니다. **앱에서 `PATCH /me`로 `missedHabitPushLocalHour`/`Minute`를 저장한 경우 그 시각이 env 기본보다 우선**합니다.
- **유저 로컬 달력** `YYYY-MM-DD`와 동일한 `recordDate`로 완료 여부를 보고 미달성을 계산합니다. `missed_habit_push_logs.pushDate`도 이 **로컬일** 기준(하루 1통).
- DB `INSERT … ON CONFLICT DO NOTHING`으로 슬롯을 먼저 잡은 뒤에만 FCM 전송(멀티 인스턴스 중복 완화).
- 푸시 `data`에 **이미지 URL**(`imageUrl`) 포함 → Android에서 앱이 URL을 받아 **로컬** Big Picture 스타일로 표시

### 6-2. 이미지 URL (필수)

앱(로컬 알림)이 Big Picture용 이미지를 다운로드할 수 있어야 하므로, 서버가 **공개 URL**로 이미지를 제공해야 합니다.

- 서버 라우트: `GET /static/missed_habit.png` (기본 1x1 placeholder PNG 제공)
- `.env`에 **앱/에뮬레이터가 접근 가능한** 공개 기본 URL 설정:
  ```env
  # 에뮬레이터에서 서버가 PC 3000 포트일 때 예시
  PUBLIC_ASSET_BASE_URL=http://10.0.2.2:3000
  ```
- 실제 배포 시에는 HTTPS 공개 도메인으로 설정 (예: `https://api.yourapp.com`).

### 6-2a. 테스트 시 특정 시간에 알림 받기

- 전송 시각은 **서버가 아니라 사용자 타임존의 로컬 시각**입니다. 기기에서 앱을 열어 `PATCH /me`로 타임존이 올라가 있는지 확인하세요.
- **틱 주기 늘리기**: `MISSED_HABIT_TICK_CRON=*/2 * * * `* 등으로 바꿀 수 있습니다(테스트 후 원복 권장).
- **전송 창 넓히기**: `MISSED_HABIT_SEND_WINDOW_MINUTES=120` 등.
- **즉시 한 번 보내기**: `.env`에 `MISSED_HABIT_RUN_ON_START=true` 후 서버 재시작 → 기동 시 `force` 경로로 전송(이미 해당 로컬일에 로그가 있으면 `force`가 로그를 지우고 다시 시도).

### 6-3. 확인 방법 (자세히)

#### ① 서버 재시작 후 로그 확인

1. 서버를 **한 번 종료**(Ctrl+C)한 뒤 다시 실행: `npm run start:dev`
2. 터미널에서 아래 로그가 나오는지 확인합니다.
  - `[MissedHabitReminder] runOnce start (force=…, sendLocal=23:00+10m)`  
  - `[MissedHabitReminder] sending to user=… pushDate=YYYY-MM-DD missedCount=…`  
  - `[MissedHabitReminder] runOnce done. sent=N`

**참고:** `.env`에 `MISSED_HABIT_RUN_ON_START=true`가 있어야 서버 시작 시 `force`로 한 번 돕니다. 없으면 `MISSED_HABIT_TICK_CRON` 주기마다 전송 창에 들어온 유저만 처리됩니다.

---

#### ② 강제 전송으로 앱/에뮬레이터에서 푸시 확인

전송 창을 기다리지 않고 **지금 바로** 푸시가 오는지 테스트하는 방법입니다.

**권장: 서버 기동 시 한 번 실행**

1. `.env`에 `MISSED_HABIT_RUN_ON_START=true` 추가 후 서버 재시작.
2. 터미널에 `[MissedHabitReminder] sending to user=…` 로그가 나오는지 확인합니다.
3. 테스트가 끝나면 해당 줄을 제거하거나 `false`로 두고 재시작합니다.

**앱/에뮬레이터에서 확인**

- 테스트할 **앱 사용자**는 **오늘 습관을 하나라도 완료하지 않은** 상태여야 합니다.
- 해당 사용자로 **앱에 로그인**한 뒤 **홈**까지 한 번 들어가서 FCM 토큰이 서버에 등록된 상태여야 합니다.
- 서버가 기동 직후 `runOnce`를 돌린 뒤 **잠시**(수 초 이내) 해당 사용자 기기/에뮬레이터에 푸시 알림이 와야 합니다.
  - 제목: "오늘도 놓친 습관이 있어요"
  - 본문: 습관명 + "1일 미달성" 또는 "외 N개 미달성"
- **에뮬레이터**에서는 Google Play 서비스가 있는 이미지로 실행해야 푸시가 올 수 있고, 실제 기기보다 푸시가 안 올 수 있습니다. 실제 기기에서도 한 번 확인하는 것을 권장합니다.

---

#### ③ Big Picture 이미지(잠금 화면)가 안 보일 때

- 푸시는 오는데 **이미지(큰 그림)** 가 잠금 화면에 안 나오는 경우, 앱이 `data.imageUrl`에서 받아오는 **URL**을 확인합니다.
- 서버가 제공하는 URL: `{PUBLIC_ASSET_BASE_URL}/static/missed_habit.png`
- **에뮬레이터**에서 서버가 PC의 3000 포트라면, `.env`에 다음을 넣고 서버를 재시작합니다.
  ```env
  PUBLIC_ASSET_BASE_URL=http://10.0.2.2:3000
  ```
  (에뮬레이터 안에서는 `localhost`가 에뮬레이터 자신을 가리키므로, PC를 가리키는 `10.0.2.2`를 씁니다.)
- **접근 가능 여부 확인**  
  - PC 브라우저: `http://localhost:3000/static/missed_habit.png` 로 열려서 이미지(또는 1x1 placeholder)가 보이면 서버 제공은 정상입니다.
  - 에뮬레이터/기기에서는 위 URL이 **해당 환경에서 접근 가능한 주소**여야 앱이 이미지를 다운로드해 Big Picture로 띄울 수 있습니다. 배포 시에는 `https://` 공개 도메인으로 설정하는 것이 좋습니다.

---

#### ④ 이미지 교체 (선택)

- 현재 `/static/missed_habit.png` 는 **1x1 placeholder** PNG입니다.  
- 나중에 원하는 디자인 이미지를 서버에서 같은 경로로 서빙하도록 바꾸면, **URL은 그대로** 두고 Big Picture 이미지만 교체할 수 있습니다.  
  - 예: `server/src/static/` 에 `missed_habit.png` 파일을 두고, 해당 컨트롤러에서 그 파일을 읽어 응답하도록 수정.

