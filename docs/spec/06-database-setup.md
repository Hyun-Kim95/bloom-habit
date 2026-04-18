# 서버 DB 연동 (PostgreSQL)

서버는 **PostgreSQL**만 사용합니다. 아래만 하시면 됩니다.

---

## 1. 사용자가 할 일 (최소)

### 1) PostgreSQL 설치 및 DB 생성

- 로컬에 PostgreSQL 설치 후, 전용 DB 하나 생성합니다.

  ```sql
  CREATE DATABASE bloom_habit;
  ```

- (선택) 전용 사용자 생성:

  ```sql
  CREATE USER bloom_user WITH PASSWORD 'your_password';
  GRANT ALL PRIVILEGES ON DATABASE bloom_habit TO bloom_user;
  ```

### 2) 환경 변수 설정

서버 실행 시 **`DATABASE_URL`** 이 필요합니다.

**`server` 폴더 안에 `.env` 파일을 만들고** 아래처럼 적습니다.

- 파일 위치: **`server/.env`**
- 형식: `postgresql://사용자:비밀번호@호스트:포트/DB이름`
- 예 (로컬): `postgresql://postgres:postgres@localhost:5432/bloom_habit`

```bash
# server/.env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/bloom_habit
```

참고: `server/.env.example`에 예시가 있으니 복사한 뒤 값을 바꿔 쓰면 됩니다. (`.env`는 git에 올라가지 않습니다.)

- 관리자 초기 계정 (선택):
  - `ADMIN_EMAIL`: 관리자 로그인 이메일 (기본: `admin@bloom.local`)
  - `ADMIN_PASSWORD`: 비밀번호 (기본: `admin123`)
  - 서버 기동 시 해당 이메일이 없으면 위 값으로 관리자 계정이 자동 생성됩니다.

### 3) 서버 실행

```bash
cd server
npm install
npm run start:dev
```

- **테이블**: `NODE_ENV !== 'production'` 이면 엔티티 기준으로 테이블이 자동 생성됩니다.  
- **운영**에서는 `NODE_ENV=production` 으로 두고, `synchronize`는 코드에서 이미 비활성화되어 있으므로 마이그레이션으로 스키마 관리하는 것을 권장합니다.

---

## 2. 정리

| 항목 | 내용 |
|------|------|
| DB | PostgreSQL 전용 |
| 필수 환경 변수 | `DATABASE_URL` |
| 선택 환경 변수 | `ADMIN_EMAIL`, `ADMIN_PASSWORD` |
| 테이블 생성 | 개발 시 자동 (`synchronize`), 운영 시 마이그레이션 권장 |

위만 하시면 서버가 PostgreSQL에 연결되어 동작합니다. 엔티티·Repository·서비스 코드는 이미 적용되어 있습니다.

---

## 3. 앱 실행 시 (서버 연결)

- **서버를 먼저 실행**해 두어야 앱이 연결할 수 있습니다. (`cd server` → `npm run start:dev`)
- **Android 에뮬레이터**: 기본 주소 `http://10.0.2.2:3000` 사용 (별도 설정 없음).
- **실기기(휴대폰)**: 같은 Wi-Fi에 연결한 뒤, PC IP로 접속해야 합니다.
  - PC IP 확인 (예: `192.168.0.5`) 후 실행:
  - `flutter run --dart-define=API_BASE_URL=http://192.168.0.5:3000`
- 연결이 안 되면 앱에 "서버에 연결할 수 없습니다" 안내가 표시됩니다.
