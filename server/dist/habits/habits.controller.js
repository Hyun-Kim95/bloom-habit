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
exports.HabitsController = void 0;
const common_1 = require("@nestjs/common");
const ai_feedback_service_1 = require("./ai-feedback.service");
const jwt_guard_1 = require("./jwt.guard");
const habits_service_1 = require("./habits.service");
let HabitsController = class HabitsController {
    habits;
    aiFeedbackService;
    constructor(habits, aiFeedbackService) {
        this.habits = habits;
        this.aiFeedbackService = aiFeedbackService;
    }
    async list(req, archived) {
        return this.habits.list(req.userId, archived === 'true');
    }
    async get(req, id) {
        const h = await this.habits.get(id, req.userId);
        if (!h)
            return { statusCode: 404, message: 'Not found' };
        return h;
    }
    async create(req, body) {
        try {
            return await this.habits.create(req.userId, {
                name: body.name,
                category: body.category,
                goalType: body.goalType ?? 'completion',
                goalValue: body.goalValue,
                startDate: body.startDate,
                colorHex: body.colorHex,
                iconName: body.iconName,
            });
        }
        catch (e) {
            const message = e instanceof Error ? e.message : String(e);
            throw new common_1.InternalServerErrorException(message);
        }
    }
    async update(req, id, body) {
        const h = await this.habits.update(id, req.userId, body);
        if (!h)
            return { statusCode: 404, message: 'Not found' };
        return h;
    }
    async delete(req, id) {
        const ok = await this.habits.delete(id, req.userId);
        if (!ok)
            return { statusCode: 404, message: 'Not found' };
        return { ok: true };
    }
    async listRecords(req, habitId, from, to) {
        return this.habits.listRecords(habitId, req.userId, from, to);
    }
    async addRecord(req, habitId, body) {
        const r = await this.habits.addRecord(habitId, req.userId, body);
        if (!r)
            return { statusCode: 404, message: 'Habit not found' };
        return r;
    }
    async aiFeedback(req, habitId, recordId) {
        try {
            return await this.aiFeedbackService.requestFeedback(req.userId, habitId, recordId);
        }
        catch (e) {
            return { statusCode: 404, message: e.message };
        }
    }
};
exports.HabitsController = HabitsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('archived')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "list", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "get", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "delete", null);
__decorate([
    (0, common_1.Get)(':habitId/records'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('habitId')),
    __param(2, (0, common_1.Query)('from')),
    __param(3, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "listRecords", null);
__decorate([
    (0, common_1.Post)(':habitId/records'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('habitId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "addRecord", null);
__decorate([
    (0, common_1.Post)(':habitId/records/:recordId/ai-feedback'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('habitId')),
    __param(2, (0, common_1.Param)('recordId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], HabitsController.prototype, "aiFeedback", null);
exports.HabitsController = HabitsController = __decorate([
    (0, common_1.Controller)('habits'),
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    __metadata("design:paramtypes", [habits_service_1.HabitsService,
        ai_feedback_service_1.AiFeedbackService])
], HabitsController);
//# sourceMappingURL=habits.controller.js.map