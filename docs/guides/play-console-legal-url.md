# Play Console 법률 문서 URL 운영 가이드

Google Play Console의 개인정보처리방침 URL은 로그인 없이 브라우저에서 열리는 공개 페이지여야 합니다.
HabitFable 서버는 최신 약관/개인정보 버전을 읽어 HTML 페이지로 노출합니다.

## 공개 URL 경로

- 개인정보처리방침: `/legal/privacy-page?locale=ko`
- 이용약관: `/legal/terms-page?locale=ko`
- 영어 페이지가 필요하면 `locale=en` 사용

예시:

- `https://api.example.com/legal/privacy-page?locale=ko`
- `https://api.example.com/legal/terms-page?locale=ko`

## 동작 방식

- 서버는 DB의 최신 버전 문서를 기준으로 페이지를 렌더링합니다.
- `locale=en` 요청 시 영어 문서가 없으면 한국어 최신 문서로 fallback 됩니다.
- 문서가 비어 있으면 안내 문구를 반환합니다(404 미반환).

## Play Console 입력 체크리스트

- HTTPS URL인지 확인
- 비로그인 상태(시크릿 창)에서 열리는지 확인
- 모바일 브라우저에서도 본문이 읽히는지 확인
- 관리자에서 문서 수정 후 URL 새로고침 시 최신 내용이 보이는지 확인

## 앱 내 확인

앱 약관/개인정보 화면 우상단의 `브라우저에서 보기` 버튼으로 동일 공개 URL을 열 수 있습니다.
