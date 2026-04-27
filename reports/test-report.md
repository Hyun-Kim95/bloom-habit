# 테스트 보고 — 수익화(AdMob + 인앱 결제)

**일자:** 2026-04-10  
**범위:** 광고 슬롯, 설정 → 후원 및 광고 제거 화면, `in_app_purchase` / `google_mobile_ads` 의존성 추가

## 자동 테스트

| 명령 | 결과 |
|------|------|
| `flutter test` | 통과 (`test/widget_test.dart` 스모크) |
| `flutter analyze lib/core/monetization lib/features/monetization lib/main.dart lib/core/router/main_shell.dart` | 이슈 없음 |

## 미검증 / 수동 확인 필요

실제 **Google Play Console** 인앱 상품·**AdMob** 단위와 연결한 기기/내부 테스트 트랙에서만 다음을 최종 확인할 수 있습니다.

1. Play Console에 `remove_ads`(비소모), `donation_small` / `donation_medium`(소모) 등록 후, 내부 테스트 빌드에서 상품 로드·결제·복원.
2. `android/local.properties`의 `ADMOB_APP_ID` 및 `--dart-define=BANNER_AD_UNIT_ID=...`로 실 광고 단위 노출(또는 테스트 단위 유지).
3. 광고 제거 구매 후 메인 탭 하단 배너가 사라지는지, 앱 재실행 후에도 `SharedPreferences` 플래그로 숨김이 유지되는지.
4. iOS: Xcode In-App Purchase capability, `Info.plist`의 `GADApplicationIdentifier` 실앱 ID 반영.

## 비고

- 웹/Windows 등 **모바일 스토어가 아닌 플랫폼**에서는 배너·결제 UI가 비활성 안내만 표시됩니다.
