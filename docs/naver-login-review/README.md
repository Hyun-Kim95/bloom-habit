# 네이버 로그인 검수 — 서비스 소개 PDF

## 산출물

| 파일 | 설명 |
|------|------|
| `service-intro.html` | 서비스 소개 원본(인쇄·PDF 변환용) |
| `HabitFable-naver-login-service-intro.pdf` | 제출용 PDF (`generate-pdf.ps1` 실행 후 생성) |
| `screenshots/` | 앱 캡처 PNG (아래 파일명) |

## PDF 생성

```powershell
cd docs\naver-login-review
.\generate-pdf.ps1
```

## Git

`screenshots/*.png`는 `.gitignore`에 포함됩니다(네이버 ID·이메일 등 개인정보).  
레포에는 HTML·PDF·스크립트만 커밋하고, 캡처는 로컬에만 보관하세요.

## 캡처 권장 (제출 전)

`screenshots/` 폴더에 아래 파일을 넣은 뒤 PDF를 다시 생성하세요.  
실기기·에뮬레이터: `flutter run --dart-define=SCREENSHOT_MODE=true` (광고·디버그 배너 숨김)

| 파일명 | 화면 |
|--------|------|
| `01-login.png` | 로그인 (네이버 버튼 보이게) |
| `02-home.png` | 홈(로그인 완료 후) |
| `03-habits.png` | 습관 목록 |
| `04-habit-create.png` | 습관 추가 |
| `05-statistics.png` | 통계 |
| `06-settings.png` | 설정 |
| `07-account.png` | 계정 관리 (닉네임·이메일·프로필 사진) |
| `08-inquiry.png` | 문의하기 |

개인정보는 마스킹 후 저장하세요.

## 네이버 검수 별도 첨부

- **로그인 절차 캡처:** 로그인 → 네이버 동의 → 홈 (검수 폼 전용 슬롯)
- **제공 정보 활용:** `07-account.png` 등 계정 화면 (API 설정 화면·동의창만 제출 금지)
