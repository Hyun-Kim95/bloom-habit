# ERD 및 API 명세 초안

**버전:** 0.1  
**작성일:** 2026-03-17  
**상태:** 초안 (개발 중 구체화)

---

## 1. ERD (엔티티·관계)

### 1.1 핵심 엔티티

#### User
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 사용자 식별자 |
| email | string (nullable) | 이메일 (소셜에서 제공 시) |
| display_name | string (nullable) | 표시명 |
| created_at | timestamp | 가입 시각 |
| updated_at | timestamp | 수정 시각 |

#### AuthAccount
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 계정 식별자 |
| user_id | UUID FK → User | 소유 사용자 |
| provider | string | "google" \| "apple" |
| provider_uid | string | provider 측 고유 ID |
| created_at | timestamp | 연동 시각 |
| UNIQUE(provider, provider_uid) | | 중복 가입 방지 |

#### Habit
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 습관 식별자 |
| user_id | UUID FK → User | 소유 사용자 |
| name | string | 습관명 |
| category | string (nullable) | 카테고리 |
| goal_type | string | "completion" \| "count" \| "duration" \| "number" |
| goal_value | number (nullable) | 목표 값 (횟수/시간 등) |
| start_date | date | 시작일 |
| color_hex | string (nullable) | 색상 |
| icon_name | string (nullable) | 아이콘 |
| archived_at | timestamp (nullable) | 아카이브 시각 (삭제 대신) |
| created_at | timestamp | 생성 시각 |
| updated_at | timestamp | 수정 시각 |

#### HabitSchedule
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 스케줄 식별자 |
| habit_id | UUID FK → Habit | 습관 |
| repeat_type | string | "daily" \| "weekly" \| "custom" |
| repeat_config | jsonb (nullable) | 요일 등 반복 설정 |
| created_at | timestamp | 생성 시각 |
| updated_at | timestamp | 수정 시각 |

#### HabitRecord
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 기록 식별자 |
| habit_id | UUID FK → Habit | 습관 |
| record_date | date | 기록 대상 일자 |
| value | number (nullable) | 완료 횟수/시간/수치 등 |
| completed | boolean | 완료 여부 |
| created_at | timestamp | 생성 시각 |
| updated_at | timestamp | 수정 시각 |
| UNIQUE(habit_id, record_date) | | 일자당 1건 (또는 정책에 따라 유연화) |

#### HabitStats (캐시/집계)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| habit_id | UUID FK → Habit | 습관 |
| period_type | string | "day" \| "week" \| "month" |
| period_key | string | "2026-03-17", "2026-W11", "2026-03" 등 |
| achieved_count | int | 달성 일 수 |
| total_count | int | 유효 일 수 |
| streak_days | int (nullable) | 연속 달성일 |
| updated_at | timestamp | 집계 시각 |

#### UserLevel
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK → User | 사용자 |
| level | int | 현재 레벨 |
| total_points | int | 누적 포인트 |
| updated_at | timestamp | 수정 시각 |

#### NotificationSetting
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK → User | 사용자 |
| habit_id | UUID FK → Habit (nullable) | 습관(전역이면 null) |
| enabled | boolean | 알림 사용 여부 |
| time_of_day | time (nullable) | 알림 시각 |
| created_at | timestamp | |
| updated_at | timestamp | |

#### WidgetState (선택)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK → User | 사용자 |
| payload | jsonb | 위젯에 전달할 요약 데이터 |
| updated_at | timestamp | |

#### AIFeedbackLog
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK → User | 사용자 |
| habit_id | UUID FK → Habit | 습관 |
| record_id | UUID FK → HabitRecord (nullable) | 기록 |
| response_text | text | AI 응답 내용 |
| created_at | timestamp | |

#### AdminUser
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| email | string | 로그인 이메일 |
| password_hash | string | 비밀번호 해시 |
| created_at | timestamp | |
| updated_at | timestamp | |

#### HabitTemplate
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| name | string | 템플릿명 |
| category | string (nullable) | 카테고리 |
| goal_type | string | 목표 유형 |
| is_active | boolean | 노출 여부 |
| created_at | timestamp | |
| updated_at | timestamp | |

#### Notice
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| title | string | 제목 |
| body | text | 본문 |
| published_at | timestamp (nullable) | 공개 시각 |
| created_at | timestamp | |
| updated_at | timestamp | |

#### SystemConfig
| 컬럼 | 타입 | 설명 |
|------|------|------|
| key | string PK | 설정 키 |
| value | jsonb/text | 값 |
| updated_at | timestamp | |

---

### 1.2 관계 요약

- User 1:N AuthAccount  
- User 1:N Habit  
- Habit 1:1 (또는 1:N) HabitSchedule  
- Habit 1:N HabitRecord  
- User 1:1 UserLevel  
- User 1:N NotificationSetting  
- Habit 1:N AIFeedbackLog (user_id, habit_id, record_id로 연결)  
- User 1:1 WidgetState (선택)

---

## 2. API 명세 초안

### 2.1 인증

- **소셜 로그인**: `POST /auth/google`, `POST /auth/apple` (또는 토큰 검증 엔드포인트).  
  - 응답: `access_token`, `refresh_token`(선택), `user` 요약.
- **토큰 갱신**: `POST /auth/refresh` (refresh_token으로 access_token 재발급).
- **로그아웃**: `POST /auth/logout` (토큰 무효화 등).

### 2.2 사용자

- `GET /me` — 현재 사용자 프로필.
- `DELETE /me` — 회원 탈퇴.

### 2.3 습관

- `GET /habits` — 목록 (활성/아카이브 필터).
- `POST /habits` — 생성. Body: name, category, goal_type, goal_value, start_date, schedule, notification...
- `GET /habits/:id` — 상세.
- `PATCH /habits/:id` — 수정.
- `DELETE /habits/:id` — 삭제(또는 archived_at 설정).

### 2.4 기록

- `GET /habits/:habitId/records` — 기간별 기록 목록. Query: from, to.
- `POST /habits/:habitId/records` — 기록 생성. Body: record_date, value, completed.
- `PATCH /records/:id` — 수정 (정책 허용 시).
- `DELETE /records/:id` — 삭제 (정책 허용 시).

### 2.5 통계·레벨

- `GET /habits/:habitId/stats` — Query: period (day|week|month), from, to.  
  - 응답: 달성률, 연속 달성일, 기간별 달성일 수 등.
- `GET /me/level` — 현재 레벨·포인트.
- `GET /me/heatmap` 또는 `GET /habits/:habitId/heatmap` — 히트맵용 일별 달성 데이터.

### 2.6 AI 코멘트

- `POST /habits/:habitId/records/:recordId/ai-feedback` — AI 코멘트 요청.  
  - 응답: response_text (또는 fallback).  
  - 제한: 일일 30회, (user, habit, date)당 1회.

### 2.7 알림 설정

- `GET /notification-settings` — 목록.
- `PUT /notification-settings` — 일괄 저장.

### 2.8 동기화

- `GET /sync` — Query: since (ISO timestamp).  
  - 응답: 변경된 habits, records, user_level 등 (증분).
- `POST /sync/push` — 로컬 변경분 푸시 (생성/수정/삭제 배치).

### 2.9 관리자 (별도 prefix, 예: /admin)

- `POST /admin/auth/login` — 관리자 로그인.
- `GET /admin/users` — 회원 목록/검색.
- `GET /admin/habit-templates`, `POST`, `PATCH`, `DELETE` — 습관 템플릿.
- `GET /admin/notices`, `POST`, `PATCH`, `DELETE` — 공지.
- `GET /admin/system-config`, `PATCH` — AI fallback 문구 등 설정.
- `GET /admin/stats` — 대시보드용 기본 통계.

---

## 3. 변경 이력

| 버전 | 일자 | 변경 내용 |
|------|------|-----------|
| 0.1 | 2026-03-17 | 초안 작성 |
