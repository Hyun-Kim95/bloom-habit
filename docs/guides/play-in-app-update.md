# Play In-app update 운영 가이드

Android 앱의 업데이트 알림은 **Google Play In-app Update API**로만 동작합니다.  
어드민·서버에서 build 번호를 맞출 필요가 **없습니다**.

구현: `lib/core/version/` (`PlayUpdateChecker`, `updatePriority` 분기)

---

## 권장 업데이트만 쓸 때 (기본)

**추가 작업 없음.** 평소 출시와 동일합니다.

1. [`pubspec.yaml`](../../pubspec.yaml)에서 `version`·**build**(`+숫자`)를 이전보다 크게 올린다.
2. AAB를 빌드해 Play Console 해당 트랙(비공개 테스트·프로덕션 등)에 업로드한다.
3. 심사·**게시**까지 완료한다.

Play에 priority를 따로 넣지 않으면 기본값은 **0**이며, 앱은 **권장** 흐름(다이얼로그 + flexible update, 나중에 / 오늘 하루 안 보기)으로 동작합니다.

| 하지 않아도 되는 것 |
|-------------------|
| Play Console에서 「In-app update priority」 찾기·설정 (UI가 없는 경우가 많음) |
| 어드민 **시스템 설정**에서 버전·build 입력 |
| 서버 배포 (업데이트 알림과 무관) |
| Play Developer API |

### 동작 조건

- 사용자 기기에 **Play 스토어 경유로 설치**된 앱이어야 한다. (비공개 테스트 초대 링크 포함)
- **구버전**을 실행할 때, **같은 트랙**에 **더 높은 versionCode**의 AAB가 이미 **게시(live)** 상태여야 한다.
- 로컬 **debug APK / sideload**만 있으면 In-app update가 동작하지 않을 수 있고, Play Store 링크 fallback만 확인된다.

---

## 강제 업데이트에 가깝게 쓸 때 (선택)

앱은 Play가 내려주는 `updatePriority`가 **4 이상**이면 immediate(강제에 가까운) 다이얼로그를 띄웁니다. 임계값: [`lib/core/version/app_update_config.dart`](../../lib/core/version/app_update_config.dart)의 `kImmediateUpdatePriorityThreshold` (기본 **4**).

| priority | 앱 UX |
|----------|--------|
| 0~3 (기본) | 권장 — flexible, 닫기·스누즈 가능 |
| 4~5 | 강제에 가까움 — immediate, 다이얼로그 닫기 불가 |

**중요:** Google Play Console 화면에는 **In-app update priority 입력란이 없는 경우가 많습니다.**  
강제 수준을 올리려면 **Play Developer API**의 `inAppUpdatePriority`(0~5)를 릴리즈에 넣어야 합니다.

- API: [Edits.tracks.releases](https://developers.google.com/android-publisher/api-ref/edits/tracks) — `inAppUpdatePriority`
- 문서: [Support in-app updates](https://developer.android.com/guide/playcore/in-app-updates)
- CI 예: Gradle Play Publisher의 `updatePriority.set(5)` 등

이미 **롤아웃이 끝난** 릴리즈만 priority를 바꾸기 어렵다는 제약이 있으므로, **새 버전을 올릴 때** API·CI와 함께 priority를 지정하는 방식을 권장합니다.

---

## 출시 체크리스트

### 권장만 (매번)

- [ ] `pubspec.yaml` build 증가
- [ ] AAB 업로드·게시
- [ ] (선택) Play 설치 구버전 → 신버전 다이얼로그 확인

### 강제까지

- [ ] 위 항목 +
- [ ] Play Developer API(또는 CI)로 `inAppUpdatePriority` **4~5** 설정
- [ ] 해당 트랙에 신버전 live 확인

---

## iOS

iOS는 아직 In-app update 체크를 하지 않습니다. App Store 출시 시 별도(`upgrader` 등) 검토 예정.

---

## DB 정리 (선택)

예전에 쓰던 `system_config` 키 `app_version_*`는 앱·서버가 더 이상 읽지 않습니다. 필요 시 DB에서 수동 삭제해도 됩니다.
