import type { AdminLang } from './messages'

/** Default habit category labels (config seed) — KO → EN for admin display */
export const CATEGORY_KO_TO_EN: Record<string, string> = {
  건강: 'Health',
  운동: 'Exercise',
  독서: 'Reading',
  학습: 'Study',
  명상: 'Mindfulness',
  취미: 'Hobby',
  업무: 'Work',
  생활: 'Daily life',
}

/** Sample template names from server default-habit-templates.ts — KO → EN */
export const SAMPLE_TEMPLATE_NAME_KO_TO_EN: Record<string, string> = {
  '아침 물 한 잔': 'A glass of water in the morning',
  '일찍 자기': 'Go to bed early',
  '비타민 챙기기': 'Take vitamins',
  '가볍게 걷기 10분': 'Walk lightly for 10 min',
  '계단 이용하기': 'Take the stairs',
  '스트레칭 5분': 'Stretch for 5 min',
  '책 읽기 15분': 'Read for 15 min',
  '온라인 강의 1강': 'One online lesson',
  '영단어 10개': '10 English words',
  '명상 5분': 'Meditate for 5 min',
  '감사 일기 한 줄': 'One-line gratitude journal',
  '악기 연습 15분': 'Practice instrument 15 min',
  '그림·스케치': 'Drawing / sketch',
  '오늘 할 일 정리': 'Plan today’s tasks',
  '이메일 정리': 'Tidy up email',
  '침대 정리': 'Make the bed',
  '설거지하기': 'Do the dishes',
  '물 8잔 마시기': 'Drink 8 glasses of water',
  팔굽혀펴기: 'Push-ups',
  '영단어 복습 카드': 'Vocabulary review cards',
  '집중 독서': 'Focused reading',
  '영어 팟캐스트 듣기': 'Listen to English podcast',
  '유산소 운동': 'Cardio exercise',
  '하루 걸음 수': 'Daily step count',
  '공부·업무 집중 기록': 'Study/work focus log',
}

export function displayCategory(ko: string | undefined | null, lang: AdminLang): string {
  if (ko == null || ko === '') return ''
  if (lang !== 'en') return ko
  return CATEGORY_KO_TO_EN[ko] ?? ko
}

export function displaySampleTemplateName(name: string | undefined | null, lang: AdminLang): string {
  if (name == null || name === '') return ''
  if (lang !== 'en') return name
  return SAMPLE_TEMPLATE_NAME_KO_TO_EN[name] ?? name
}

export function displayNoticeTitle(
  n: { title: string; titleEn?: string | null },
  lang: AdminLang,
): string {
  if (lang === 'en' && n.titleEn?.trim()) return n.titleEn.trim()
  return n.title
}

export function displayNoticeBody(
  n: { body: string; bodyEn?: string | null },
  lang: AdminLang,
): string {
  if (lang === 'en' && n.bodyEn?.trim()) return n.bodyEn.trim()
  return n.body
}

export function displayTemplateNameStored(
  row: { name: string; nameEn?: string | null },
  lang: AdminLang,
): string {
  if (lang === 'en' && row.nameEn?.trim()) return row.nameEn.trim()
  return displaySampleTemplateName(row.name, lang)
}

export function displayTemplateCategoryStored(
  row: { category?: string | null; categoryEn?: string | null },
  lang: AdminLang,
): string {
  if (lang === 'en' && row.categoryEn?.trim()) return row.categoryEn.trim()
  if (!row.category) return ''
  return displayCategory(row.category, lang)
}
