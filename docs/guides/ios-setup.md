# iOS 설정: Bundle ID, Team ID, App Store ID

## 1. Bundle ID (번들 ID)

- **현재 값**: `com.example.bloomHabit`
- **위치**: Xcode에서 **Runner** 타깃 → **General** → **Bundle Identifier**
- **또는**: `ios/Runner.xcodeproj/project.pbxproj` 에서 `PRODUCT_BUNDLE_IDENTIFIER` 검색 후 수정
- **변경 시**: 나중에 배포할 때 Apple Developer / App Store Connect에 등록하는 Bundle ID와 동일해야 합니다. 테스트만 할 때는 그대로 둬도 됩니다.

---

## 2. Team ID (팀 ID)

- **뭐하는 값인지**: Apple Developer 계정의 **팀**을 구분하는 ID. 코드 서명·프로비저닝에 사용됩니다.
- **어디서 확인**:
  1. [Apple Developer](https://developer.apple.com/account) 로그인
  2. **Membership** (멤버십) → **Team ID** 에 10자리 영문+숫자 (예: `ABC123DEFG`)
- **Xcode에 넣는 법** (권장):
  1. Xcode에서 `ios/Runner.xcworkspace` 열기
  2. 왼쪽에서 **Runner** 프로젝트 선택 → **Runner** 타깃 선택
  3. **Signing & Capabilities** 탭
  4. **Team** 드롭다운에서 본인 Apple ID 팀 선택  
     → 선택하면 **Team ID** 가 자동으로 들어갑니다.
- **직접 넣기**: `ios/Runner.xcodeproj/project.pbxproj` 에서 `DEVELOPMENT_TEAM` 검색 후 `YOUR_TEAM_ID` 를 본인 Team ID로 바꿉니다.

---

## 3. App Store ID

- **뭐하는 값인지**: 앱을 **App Store에 한 번 올린 뒤** Apple이 부여하는 숫자 ID (예: `1234567890`).  
  스토어 링크, 평점 요청 등에 쓰입니다.
- **지금 단계**: 아직 스토어에 올리지 않았으면 **비워 두거나 0** 으로 두면 됩니다.
- **나중에 확인**: App Store Connect → 앱 선택 → **App Information** → **Apple ID** (숫자)

---

## 요약

| 항목        | 현재/설정 방법                    |
|------------|-----------------------------------|
| Bundle ID  | `com.example.bloomHabit` (필요 시 수정) |
| Team ID    | Apple Developer → Membership에서 확인 후 Xcode **Signing & Capabilities** → Team 에서 선택 |
| App Store ID | 앱 출시 전이면 비워 두거나 0        |

**Sign in with Apple** 이나 **Google 로그인(iOS)** 설정 시에는 보통 **Bundle ID** 와 **Team ID** 만 맞추면 됩니다. App Store ID는 스토어에 올린 뒤 필요할 때 넣으면 됩니다.
