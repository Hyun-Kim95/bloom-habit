"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiFeedbackService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const habits_service_1 = require("./habits.service");
const entities_1 = require("../entities");
const uuid_1 = require("uuid");
const DAILY_LIMIT = 30;
const FALLBACKS = [
    '오늘도 수고했어요!',
    '꾸준함이 쌓여가고 있어요.',
    '내일도 화이팅!',
    '작은 습관이 큰 변화를 만듭니다.',
    '잘 하고 있어요.',
];
function logKey(userId, habitId, recordDate) {
    return `${userId}:${habitId}:${recordDate}`;
}
let AiFeedbackService = class AiFeedbackService {
    habits;
    feedbackRepo;
    constructor(habits, feedbackRepo) {
        this.habits = habits;
        this.feedbackRepo = feedbackRepo;
    }
    async requestFeedback(userId, habitId, recordId) {
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
        const today = recordDate.slice(0, 10);
        const todayStart = new Date(today + 'T00:00:00.000Z');
        const todayEnd = new Date(today + 'T23:59:59.999Z');
        const dailyCount = await this.feedbackRepo
            .createQueryBuilder('f')
            .where('f.userId = :userId', { userId })
            .andWhere('f.createdAt >= :start', { start: todayStart })
            .andWhere('f.createdAt <= :end', { end: todayEnd })
            .getCount();
        if (dailyCount >= DAILY_LIMIT) {
            const fallback = FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
            return { response_text: fallback };
        }
        const habit = await this.habits.get(habitId, userId);
        let responseText;
        try {
            responseText = await this.callOpenAI(habit, record);
        }
        catch {
            responseText = FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
        }
        const log = this.feedbackRepo.create({
            id: (0, uuid_1.v4)(),
            userId,
            habitId,
            recordDate,
            recordId,
            responseText,
        });
        await this.feedbackRepo.save(log);
        return { response_text: responseText };
    }
    async callOpenAI(habit, _record) {
        const apiKey = process.env.OPENAI_API_KEY;
        if (!apiKey) {
            return FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
        }
        const habitName = habit?.name ?? '습관';
        const res = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${apiKey}`,
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                max_tokens: 80,
                messages: [
                    {
                        role: 'user',
                        content: `사용자가 오늘 "${habitName}" 습관을 완료했습니다. 한 문장으로 짧고 따뜻한 격려 한마디만 한국어로 답해 주세요. 이모지 없이.`,
                    },
                ],
            }),
        });
        if (!res.ok) {
            const err = await res.text();
            throw new Error(err);
        }
        const data = (await res.json());
        const text = data.choices?.[0]?.message?.content?.trim();
        if (text)
            return text;
        throw new Error('No content');
    }
};
exports.AiFeedbackService = AiFeedbackService;
exports.AiFeedbackService = AiFeedbackService = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, typeorm_1.InjectRepository)(entities_1.AiFeedbackLog)),
    __metadata("design:paramtypes", [habits_service_1.HabitsService,
        typeorm_2.Repository])
], AiFeedbackService);
//# sourceMappingURL=ai-feedback.service.js.map