# 릴리즈 노트 (요약)

## 2026-04-10 — 수익화 MVP

- **AdMob**: 메인 탭(홈·습관·통계·설정)에서 하단 내비 바로 위에 적응형 배너 슬롯 추가. 광고 제거 구매 시 숨김.
- **인앱 결제**: `remove_ads`(비소모), `donation_small` / `donation_medium`(소모). 설정 → **후원 및 광고 제거**에서 구매·복원.
- **문서**: `docs/spec/11-monetization-admob-iap.md`, README 수익화 절 추가.

**운영 시 필수:** Play Console / App Store Connect에 동일 상품 ID 등록, `android/local.properties`의 `ADMOB_APP_ID` 및 릴리스용 배너 단위 ID(`BANNER_AD_UNIT_ID`) 설정.
