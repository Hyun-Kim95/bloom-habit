# 수익화: AdMob + 인앱 결제 (광고 제거·후원)

**작성일:** 2026-04-10  
**범위:** Flutter 앱(Android/iOS). 서버 검증 없음(MVP).

## 1. 모델

- **배너 광고**: 메인 탭(홈·습관·통계·설정) 하단 내비 위에 고정 슬롯(지원 플랫폼만).
- **인앱 상품**
  - `remove_ads`: 비소모성 — 구매 시 광고 숨김(로컬 플래그 + 스토어 복원).
  - `donation_small`, `donation_medium`: 소모성 — 후원(기능 해금 없음).
- **복구**: 설정 → 후원 및 광고 제거 화면에서 「구매 복원」.

## 2. Play Console / App Store Connect

1. 앱과 동일한 **애플리케이션 ID**(Android `applicationId`, iOS 번들 ID)로 스토어에 앱 등록.
2. 인앱 상품 ID를 아래와 **동일하게** 생성 (대소문자 구분).
   - `remove_ads` — 비소모 / Non-consumable
   - `donation_small` — 소모 / Consumable
   - `donation_medium` — 소모 / Consumable
3. **내부 테스트** 트랙에 AAB 올린 뒤, 라이선스 테스트 계정으로 결제 검증.

## 3. Android 설정

### AdMob 앱 ID

- `android/local.properties`에 실제 앱 ID 권장:
  - `ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy`
- 비어 있으면 Gradle이 **Google 공식 테스트 앱 ID**로 채움(개발용). 스토어 출시 전에는 **반드시 본인 AdMob 앱 ID**로 교체.

`AndroidManifest.xml`에는 `manifestPlaceholders`의 `ADMOB_APPLICATION_ID`가 주입됩니다.

### 배너 단위 ID

- 기본: 디버그 빌드는 Google **테스트 배너 단위 ID**를 코드에서 사용.
- 릴리스에서 실제 단위를 쓰려면 빌드 시 정의:
  - `--dart-define=ANDROID_BANNER_AD_UNIT_ID=ca-app-pub-xxx/yyy`

## 4. iOS 설정

- `ios/Runner/Info.plist`에 `GADApplicationIdentifier` 추가됨(미설정 시 테스트용 샘플 ID).
- 출시 전 **본인 AdMob 앱 ID**로 교체.
- StoreKit·인앱 결제는 Xcode에서 **In-App Purchase capability** 활성화 필요.

## 5. EU/EEA·동의(UMP)

- EEA 사용자에게 개인화 광고를 보이려면 **UMP(User Messaging Platform)** 등 동의 흐름이 필요할 수 있습니다. 본 MVP에는 포함하지 않았으며, 스토어 출시·타겟 지역에 맞춰 추가하세요.

## 6. 보안(선택 이후 과제)

- 현재는 클라이언트에서 구매 상태를 신뢰합니다. 악용 방지가 필요하면 서버에서 **Google Play Developer API** 등으로 구독/비소모 구매 검증을 추가하세요.
