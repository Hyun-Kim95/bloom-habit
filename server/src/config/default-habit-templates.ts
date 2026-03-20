export type DefaultTemplateRow = {
  name: string;
  category: string;
  goalType: 'completion' | 'count' | 'duration' | 'number';
  /** completion 이면 무시(null). 그 외 목표 수치(횟수·분·수치) */
  goalValue?: number | null;
  colorHex?: string;
  iconName?: string;
};

/** DB에 템플릿이 없을 때 시드 (카테고리는 habit_categories 기본값과 맞춤) */
export const DEFAULT_HABIT_TEMPLATES: ReadonlyArray<DefaultTemplateRow> = [
  // 완료 여부
  { name: '아침 물 한 잔', category: '건강', goalType: 'completion', colorHex: '22C55E', iconName: 'local_drink' },
  { name: '일찍 자기', category: '건강', goalType: 'completion', colorHex: '22C55E', iconName: 'bedtime' },
  { name: '비타민 챙기기', category: '건강', goalType: 'completion', colorHex: '22C55E', iconName: 'check_circle' },
  { name: '가볍게 걷기 10분', category: '운동', goalType: 'completion', colorHex: '3B82F6', iconName: 'fitness_center' },
  { name: '계단 이용하기', category: '운동', goalType: 'completion', colorHex: '3B82F6', iconName: 'flag' },
  { name: '스트레칭 5분', category: '운동', goalType: 'completion', colorHex: '3B82F6', iconName: 'self_improvement' },
  { name: '책 읽기 15분', category: '독서', goalType: 'completion', colorHex: '8B5CF6', iconName: 'menu_book' },
  { name: '온라인 강의 1강', category: '학습', goalType: 'completion', colorHex: '14B8A6', iconName: 'work' },
  { name: '영단어 10개', category: '학습', goalType: 'completion', colorHex: '14B8A6', iconName: 'psychology' },
  { name: '명상 5분', category: '명상', goalType: 'completion', colorHex: 'EC4899', iconName: 'self_improvement' },
  { name: '감사 일기 한 줄', category: '명상', goalType: 'completion', colorHex: 'EC4899', iconName: 'star' },
  { name: '악기 연습 15분', category: '취미', goalType: 'completion', colorHex: 'F59E0B', iconName: 'star' },
  { name: '그림·스케치', category: '취미', goalType: 'completion', colorHex: 'F59E0B', iconName: 'eco' },
  { name: '오늘 할 일 정리', category: '업무', goalType: 'completion', colorHex: '6B7280', iconName: 'work' },
  { name: '이메일 정리', category: '업무', goalType: 'completion', colorHex: '6B7280', iconName: 'check_circle' },
  { name: '침대 정리', category: '생활', goalType: 'completion', colorHex: 'EF4444', iconName: 'bedtime' },
  { name: '설거지하기', category: '생활', goalType: 'completion', colorHex: 'EF4444', iconName: 'volunteer_activism' },
  // 횟수
  { name: '물 8잔 마시기', category: '건강', goalType: 'count', goalValue: 8, colorHex: '22C55E', iconName: 'local_drink' },
  { name: '팔굽혀펴기', category: '운동', goalType: 'count', goalValue: 20, colorHex: '3B82F6', iconName: 'fitness_center' },
  { name: '영단어 복습 카드', category: '학습', goalType: 'count', goalValue: 15, colorHex: '14B8A6', iconName: 'psychology' },
  // 시간(분)
  { name: '집중 독서', category: '독서', goalType: 'duration', goalValue: 30, colorHex: '8B5CF6', iconName: 'menu_book' },
  { name: '영어 팟캐스트 듣기', category: '학습', goalType: 'duration', goalValue: 15, colorHex: '14B8A6', iconName: 'work' },
  { name: '유산소 운동', category: '운동', goalType: 'duration', goalValue: 20, colorHex: '3B82F6', iconName: 'fitness_center' },
  // 수치
  { name: '하루 걸음 수', category: '건강', goalType: 'number', goalValue: 8000, colorHex: '22C55E', iconName: 'eco' },
  { name: '공부·업무 집중 기록', category: '업무', goalType: 'number', goalValue: 1, colorHex: '6B7280', iconName: 'work' },
];
