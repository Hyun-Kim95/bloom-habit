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
exports.AdminDataService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const uuid_1 = require("uuid");
const entities_1 = require("../entities");
const DEFAULT_AI_FALLBACK = JSON.stringify([
    '오늘도 수고했어요!',
    '꾸준함이 쌓여가고 있어요.',
    '내일도 화이팅!',
]);
let AdminDataService = class AdminDataService {
    templateRepo;
    noticeRepo;
    configRepo;
    constructor(templateRepo, noticeRepo, configRepo) {
        this.templateRepo = templateRepo;
        this.noticeRepo = noticeRepo;
        this.configRepo = configRepo;
    }
    async listTemplates() {
        const list = await this.templateRepo.find({ order: { createdAt: 'ASC' } });
        return list.map((t) => ({
            id: t.id,
            name: t.name,
            category: t.category ?? undefined,
            goalType: t.goalType,
            isActive: t.isActive,
            createdAt: t.createdAt.toISOString(),
            updatedAt: t.updatedAt.toISOString(),
        }));
    }
    async createTemplate(body) {
        const t = this.templateRepo.create({
            id: `t-${(0, uuid_1.v4)()}`,
            name: body.name,
            category: body.category,
            goalType: body.goalType ?? 'completion',
            isActive: body.isActive ?? true,
        });
        await this.templateRepo.save(t);
        return {
            id: t.id,
            name: t.name,
            category: t.category ?? undefined,
            goalType: t.goalType,
            isActive: t.isActive,
            createdAt: t.createdAt.toISOString(),
            updatedAt: t.updatedAt.toISOString(),
        };
    }
    async updateTemplate(id, body) {
        const t = await this.templateRepo.findOne({ where: { id } });
        if (!t)
            return undefined;
        Object.assign(t, body);
        await this.templateRepo.save(t);
        return {
            id: t.id,
            name: t.name,
            category: t.category ?? undefined,
            goalType: t.goalType,
            isActive: t.isActive,
            createdAt: t.createdAt.toISOString(),
            updatedAt: t.updatedAt.toISOString(),
        };
    }
    async deleteTemplate(id) {
        const result = await this.templateRepo.delete(id);
        return (result.affected ?? 0) > 0;
    }
    async listNotices() {
        const list = await this.noticeRepo.find({ order: { createdAt: 'DESC' } });
        return list.map((n) => ({
            id: n.id,
            title: n.title,
            body: n.body,
            publishedAt: n.publishedAt?.toISOString(),
            createdAt: n.createdAt.toISOString(),
            updatedAt: n.updatedAt.toISOString(),
        }));
    }
    async createNotice(body) {
        const n = this.noticeRepo.create({
            id: `n-${(0, uuid_1.v4)()}`,
            title: body.title,
            body: body.body,
            publishedAt: body.publishedAt ? new Date(body.publishedAt) : null,
        });
        await this.noticeRepo.save(n);
        return {
            id: n.id,
            title: n.title,
            body: n.body,
            publishedAt: n.publishedAt?.toISOString(),
            createdAt: n.createdAt.toISOString(),
            updatedAt: n.updatedAt.toISOString(),
        };
    }
    async updateNotice(id, body) {
        const n = await this.noticeRepo.findOne({ where: { id } });
        if (!n)
            return undefined;
        if (body.title != null)
            n.title = body.title;
        if (body.body != null)
            n.body = body.body;
        if (body.publishedAt != null)
            n.publishedAt = new Date(body.publishedAt);
        await this.noticeRepo.save(n);
        return {
            id: n.id,
            title: n.title,
            body: n.body,
            publishedAt: n.publishedAt?.toISOString(),
            createdAt: n.createdAt.toISOString(),
            updatedAt: n.updatedAt.toISOString(),
        };
    }
    async deleteNotice(id) {
        const result = await this.noticeRepo.delete(id);
        return (result.affected ?? 0) > 0;
    }
    async getConfig(key) {
        const row = await this.configRepo.findOne({ where: { key } });
        return row?.value;
    }
    async getAllConfig() {
        const rows = await this.configRepo.find();
        const out = {};
        for (const r of rows)
            out[r.key] = r.value;
        if (!('ai_fallback_messages' in out)) {
            out.ai_fallback_messages = DEFAULT_AI_FALLBACK;
        }
        return out;
    }
    async setConfig(key, value) {
        let row = await this.configRepo.findOne({ where: { key } });
        if (!row) {
            row = this.configRepo.create({ key, value });
        }
        else {
            row.value = value;
        }
        await this.configRepo.save(row);
    }
    async patchConfig(body) {
        for (const [k, v] of Object.entries(body)) {
            await this.setConfig(k, typeof v === 'string' ? v : JSON.stringify(v));
        }
    }
};
exports.AdminDataService = AdminDataService;
exports.AdminDataService = AdminDataService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(entities_1.HabitTemplate)),
    __param(1, (0, typeorm_1.InjectRepository)(entities_1.Notice)),
    __param(2, (0, typeorm_1.InjectRepository)(entities_1.SystemConfig)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], AdminDataService);
//# sourceMappingURL=admin-data.service.js.map