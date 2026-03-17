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
exports.HabitsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const uuid_1 = require("uuid");
const entities_1 = require("../entities");
function toHabitDto(e) {
    return {
        id: e.id,
        userId: e.userId,
        name: e.name,
        category: e.category ?? undefined,
        goalType: e.goalType,
        goalValue: e.goalValue ?? undefined,
        startDate: e.startDate,
        colorHex: e.colorHex ?? undefined,
        iconName: e.iconName ?? undefined,
        archivedAt: e.archivedAt ? e.archivedAt.toISOString() : undefined,
        createdAt: e.createdAt.toISOString(),
        updatedAt: e.updatedAt.toISOString(),
    };
}
function toRecordDto(e) {
    return {
        id: e.id,
        habitId: e.habitId,
        recordDate: e.recordDate,
        value: e.value ?? undefined,
        completed: e.completed,
        createdAt: e.createdAt.toISOString(),
        updatedAt: e.updatedAt.toISOString(),
    };
}
let HabitsService = class HabitsService {
    habitRepo;
    recordRepo;
    constructor(habitRepo, recordRepo) {
        this.habitRepo = habitRepo;
        this.recordRepo = recordRepo;
    }
    async list(userId, archived = false) {
        const qb = this.habitRepo
            .createQueryBuilder('h')
            .where('h.userId = :userId', { userId })
            .orderBy('h.createdAt', 'ASC');
        if (archived) {
            qb.andWhere('h.archivedAt IS NOT NULL');
        }
        else {
            qb.andWhere('h.archivedAt IS NULL');
        }
        const list = await qb.getMany();
        return list.map(toHabitDto);
    }
    async get(id, userId) {
        const h = await this.habitRepo.findOne({ where: { id, userId } });
        return h ? toHabitDto(h) : undefined;
    }
    async create(userId, body) {
        const habit = this.habitRepo.create({
            id: `h-${(0, uuid_1.v4)()}`,
            userId,
            name: body.name,
            category: body.category,
            goalType: body.goalType ?? 'completion',
            goalValue: body.goalValue,
            startDate: body.startDate,
            colorHex: body.colorHex,
            iconName: body.iconName,
            archivedAt: null,
        });
        await this.habitRepo.save(habit);
        return toHabitDto(habit);
    }
    async update(id, userId, body) {
        const h = await this.habitRepo.findOne({ where: { id, userId } });
        if (!h)
            return undefined;
        Object.assign(h, body);
        await this.habitRepo.save(h);
        return toHabitDto(h);
    }
    async delete(id, userId) {
        const h = await this.habitRepo.findOne({ where: { id, userId } });
        if (!h)
            return false;
        await this.recordRepo.delete({ habitId: id });
        await this.habitRepo.remove(h);
        return true;
    }
    async archive(id, userId) {
        const h = await this.habitRepo.findOne({ where: { id, userId } });
        if (!h)
            return undefined;
        h.archivedAt = new Date();
        await this.habitRepo.save(h);
        return toHabitDto(h);
    }
    async getRecord(recordId, userId) {
        const r = await this.recordRepo.findOne({ where: { id: recordId } });
        if (!r)
            return undefined;
        const h = await this.habitRepo.findOne({ where: { id: r.habitId, userId } });
        return h ? toRecordDto(r) : undefined;
    }
    async listRecords(habitId, userId, from, to) {
        const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
        if (!h)
            return [];
        const qb = this.recordRepo
            .createQueryBuilder('r')
            .where('r.habitId = :habitId', { habitId })
            .orderBy('r.recordDate', 'ASC');
        if (from)
            qb.andWhere('r.recordDate >= :from', { from });
        if (to)
            qb.andWhere('r.recordDate <= :to', { to });
        const list = await qb.getMany();
        return list.map(toRecordDto);
    }
    async addRecord(habitId, userId, body) {
        const h = await this.habitRepo.findOne({ where: { id: habitId, userId } });
        if (!h)
            return undefined;
        const existing = await this.recordRepo.findOne({
            where: { habitId, recordDate: body.recordDate },
        });
        if (existing) {
            existing.value = body.value ?? existing.value;
            existing.completed = body.completed;
            await this.recordRepo.save(existing);
            return toRecordDto(existing);
        }
        const record = this.recordRepo.create({
            id: `r-${(0, uuid_1.v4)()}`,
            habitId,
            recordDate: body.recordDate,
            value: body.value,
            completed: body.completed,
        });
        await this.recordRepo.save(record);
        return toRecordDto(record);
    }
    async getSyncPayload(userId, _since) {
        const habitList = await this.list(userId, true);
        const habitIds = habitList.map((h) => h.id);
        if (habitIds.length === 0) {
            return { habits: habitList, records: [] };
        }
        const recordList = await this.recordRepo
            .createQueryBuilder('r')
            .where('r.habitId IN (:...ids)', { ids: habitIds })
            .orderBy('r.recordDate', 'ASC')
            .getMany();
        return { habits: habitList, records: recordList.map(toRecordDto) };
    }
    async getTotalCounts() {
        const [totalHabits, totalRecords] = await Promise.all([
            this.habitRepo.count(),
            this.recordRepo.count(),
        ]);
        return { totalHabits, totalRecords };
    }
};
exports.HabitsService = HabitsService;
exports.HabitsService = HabitsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(entities_1.Habit)),
    __param(1, (0, typeorm_1.InjectRepository)(entities_1.HabitRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], HabitsService);
//# sourceMappingURL=habits.service.js.map