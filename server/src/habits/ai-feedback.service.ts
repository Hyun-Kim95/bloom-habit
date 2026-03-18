import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HabitsService, HabitDto, RecordDto } from './habits.service';
import { AiFeedbackLog } from '../entities';
import { ConfigService } from '../config/config.service';
import { v4 as uuidv4 } from 'uuid';

const DEFAULT_DAILY_LIMIT = 30;
const FALLBACKS = [
  '오늘도 수고했어요!',
  '꾸준함이 쌓여가고 있어요.',
  '내일도 화이팅!',
  '작은 습관이 큰 변화를 만듭니다.',
  '잘 하고 있어요.',
];

function logKey(userId: string, habitId: string, recordDate: string) {
  return `${userId}:${habitId}:${recordDate}`;
}

@Injectable()
export class AiFeedbackService {
  constructor(
    private readonly habits: HabitsService,
    @InjectRepository(AiFeedbackLog)
    private readonly feedbackRepo: Repository<AiFeedbackLog>,
    private readonly config: ConfigService,
  ) {}

  async requestFeedback(
    userId: string,
    habitId: string,
    recordId: string,
  ): Promise<{ response_text: string }> {
    const record = await this.habits.getRecord(recordId, userId);
    if (!record || record.habitId !== habitId) {
      throw new Error('Record not found');
    }
    const recordDate = record.recordDate;
    const key = logKey(userId, habitId, recordDate);

    const existing = await this.feedbackRepo.findOne({
      where: { userId, habitId, recordDate },
    });
    if (existing) {
      return { response_text: existing.responseText };
    }

    const limitStr = await this.config.get('ai_daily_limit');
    const dailyLimit = limitStr ? parseInt(limitStr, 10) : DEFAULT_DAILY_LIMIT;
    const effectiveLimit = Number.isFinite(dailyLimit) ? dailyLimit : DEFAULT_DAILY_LIMIT;

    const today = recordDate.slice(0, 10);
    const todayStart = new Date(today + 'T00:00:00.000Z');
    const todayEnd = new Date(today + 'T23:59:59.999Z');
    const dailyCount = await this.feedbackRepo
      .createQueryBuilder('f')
      .where('f.userId = :userId', { userId })
      .andWhere('f.createdAt >= :start', { start: todayStart })
      .andWhere('f.createdAt <= :end', { end: todayEnd })
      .getCount();
    if (dailyCount >= effectiveLimit) {
      const fallback = FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
      return { response_text: fallback };
    }

    const habit = await this.habits.get(habitId, userId);
    let responseText: string;
    try {
      responseText = await this.callOpenAI(habit, record);
    } catch {
      responseText = FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
    }

    const log = this.feedbackRepo.create({
      id: uuidv4(),
      userId,
      habitId,
      recordDate,
      recordId,
      responseText,
    });
    await this.feedbackRepo.save(log);

    return { response_text: responseText };
  }

  /** 앱 통계용: 해당 사용자의 최근 AI 피드백 목록 (습관명 포함) */
  async listForUser(
    userId: string,
    limit = 30,
  ): Promise<
    { habitId: string; habitName: string; recordDate: string; responseText: string; createdAt: string }[]
  > {
    const list = await this.feedbackRepo
      .createQueryBuilder('f')
      .where('f.userId = :userId', { userId })
      .orderBy('f.createdAt', 'DESC')
      .take(limit)
      .getMany();
    const habitIds = [...new Set(list.map((l) => l.habitId))];
    const nameMap = new Map<string, string>();
    for (const hid of habitIds) {
      const h = await this.habits.get(hid, userId);
      nameMap.set(hid, h?.name ?? '습관');
    }
    return list.map((l) => ({
      habitId: l.habitId,
      habitName: nameMap.get(l.habitId) ?? '습관',
      recordDate: l.recordDate,
      responseText: l.responseText,
      createdAt: l.createdAt.toISOString(),
    }));
  }

  private async callOpenAI(
    habit: HabitDto | undefined,
    _record: RecordDto,
  ): Promise<string> {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
    }
    const habitName = habit?.name ?? '습관';
    const rawTemplate = await this.config.get('ai_prompt_template');
    const template =
      rawTemplate?.trim() ||
      '사용자가 오늘 "{{habitName}}" 습관을 완료했습니다. 한 문장으로 짧고 따뜻한 격려 한마디만 한국어로 답해 주세요. 이모지 없이.';
    const content = template.replace(/\{\{habitName\}\}/g, habitName);
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        max_tokens: 80,
        messages: [{ role: 'user', content }],
      }),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(err);
    }
    const data = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const text = data.choices?.[0]?.message?.content?.trim();
    if (text) return text;
    throw new Error('No content');
  }
}
