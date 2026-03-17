# 관리자 API 사용 방법

관리자 기능은 **API만** 제공됩니다. Flutter 앱에는 관리자 화면이 없고, **브라우저나 Postman/curl**로 호출해서 확인할 수 있습니다.

---

## 1. 서버 주소

서버를 로컬에서 실행 중이라면:

- **Base URL**: `http://localhost:3000`
- 실기기/다른 PC에서 접속 시: `http://PC_IP:3000`

---

## 2. 관리자 로그인

**POST** `http://localhost:3000/admin/auth/login`

- Body (JSON): `{ "email": "이메일", "password": "비밀번호" }`
- 기본 계정 (서버 `.env`에 따로 안 넣었을 때):
  - 이메일: `admin@bloom.local`
  - 비밀번호: `admin123`
- 응답 예: `{ "accessToken": "eyJ..." }`  
  → 이 **accessToken**을 복사해 두세요.

---

## 3. 인증이 필요한 API 호출

아래 API는 모두 **Authorization** 헤더가 필요합니다.

- 헤더: `Authorization: Bearer 여기에_accessToken_붙여넣기`

예 (curl):

```bash
# 1) 로그인해서 토큰 받기 (Windows PowerShell)
$body = '{"email":"admin@bloom.local","password":"admin123"}'
$res = Invoke-RestMethod -Uri http://localhost:3000/admin/auth/login -Method Post -Body $body -ContentType "application/json"
$token = $res.accessToken

# 2) 통계 조회
Invoke-RestMethod -Uri http://localhost:3000/admin/stats -Headers @{ Authorization = "Bearer $token" }
```

예 (curl, bash):

```bash
# 1) 로그인
TOKEN=$(curl -s -X POST http://localhost:3000/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@bloom.local","password":"admin123"}' | jq -r '.accessToken')

# 2) 통계 조회
curl -s http://localhost:3000/admin/stats -H "Authorization: Bearer $TOKEN"
```

---

## 4. 관리자 API 목록

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/admin/auth/login` | 로그인 (email, password) → accessToken |
| GET | `/admin/users` | 앱 가입 사용자 목록 |
| GET | `/admin/stats` | 대시보드 통계 (totalUsers, totalHabits, totalRecords) |
| GET | `/admin/habit-templates` | 습관 템플릿 목록 |
| POST | `/admin/habit-templates` | 습관 템플릿 생성 |
| PATCH | `/admin/habit-templates/:id` | 템플릿 수정 |
| DELETE | `/admin/habit-templates/:id` | 템플릿 삭제 |
| GET | `/admin/notices` | 공지 목록 |
| POST | `/admin/notices` | 공지 생성 |
| PATCH | `/admin/notices/:id` | 공지 수정 |
| DELETE | `/admin/notices/:id` | 공지 삭제 |
| GET | `/admin/system-config` | 시스템 설정 전체 조회 (예: AI fallback 문구) |
| PATCH | `/admin/system-config` | 시스템 설정 일괄 수정 (JSON body) |

---

## 5. 브라우저에서 빠르게 확인하기

1. 서버 실행: `cd server` → `npm run start:dev`
2. **로그인**: 브라우저 콘솔 또는 확장 프로그램으로  
   `POST http://localhost:3000/admin/auth/login`  
   Body: `{"email":"admin@bloom.local","password":"admin123"}`  
   호출 후 응답의 `accessToken` 복사
3. **통계**:  
   `GET http://localhost:3000/admin/stats`  
   Headers에 `Authorization: Bearer 복사한토큰` 설정 후 호출

Postman/Insomnia를 쓰면 위 주소와 Body/Headers만 그대로 넣어서 확인할 수 있습니다.

---

## 6. 관리자 계정 변경

`server/.env`에 다음을 넣으면 **서버 기동 시** 해당 계정이 없을 때만 자동 생성됩니다.

- `ADMIN_EMAIL=원하는이메일`
- `ADMIN_PASSWORD=원하는비밀번호`

이미 있는 이메일은 덮어쓰지 않습니다.
