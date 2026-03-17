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
exports.AdminController = void 0;
const common_1 = require("@nestjs/common");
const auth_service_1 = require("../auth/auth.service");
const habits_service_1 = require("../habits/habits.service");
const admin_auth_service_1 = require("./admin-auth.service");
const admin_data_service_1 = require("./admin-data.service");
const admin_guard_1 = require("./admin.guard");
let AdminController = class AdminController {
    adminAuth;
    adminData;
    auth;
    habits;
    constructor(adminAuth, adminData, auth, habits) {
        this.adminAuth = adminAuth;
        this.adminData = adminData;
        this.auth = auth;
        this.habits = habits;
    }
    async login(body) {
        return this.adminAuth.login(body.email, body.password);
    }
    async users() {
        return this.auth.getAppUsers();
    }
    async stats() {
        const users = await this.auth.getAppUsers();
        const counts = await this.habits.getTotalCounts();
        return {
            totalUsers: users.length,
            totalHabits: counts.totalHabits,
            totalRecords: counts.totalRecords,
        };
    }
    async listTemplates() {
        return this.adminData.listTemplates();
    }
    async createTemplate(body) {
        return this.adminData.createTemplate(body);
    }
    async updateTemplate(id, body) {
        const t = await this.adminData.updateTemplate(id, body);
        if (!t)
            return { statusCode: 404, message: 'Not found' };
        return t;
    }
    async deleteTemplate(id) {
        const ok = await this.adminData.deleteTemplate(id);
        if (!ok)
            return { statusCode: 404, message: 'Not found' };
        return { ok: true };
    }
    async listNotices() {
        return this.adminData.listNotices();
    }
    async createNotice(body) {
        return this.adminData.createNotice(body);
    }
    async updateNotice(id, body) {
        const n = await this.adminData.updateNotice(id, body);
        if (!n)
            return { statusCode: 404, message: 'Not found' };
        return n;
    }
    async deleteNotice(id) {
        const ok = await this.adminData.deleteNotice(id);
        if (!ok)
            return { statusCode: 404, message: 'Not found' };
        return { ok: true };
    }
    async getConfig() {
        return this.adminData.getAllConfig();
    }
    async patchConfig(body) {
        await this.adminData.patchConfig(body);
        return this.adminData.getAllConfig();
    }
};
exports.AdminController = AdminController;
__decorate([
    (0, common_1.Post)('auth/login'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "login", null);
__decorate([
    (0, common_1.Get)('users'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "users", null);
__decorate([
    (0, common_1.Get)('stats'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "stats", null);
__decorate([
    (0, common_1.Get)('habit-templates'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "listTemplates", null);
__decorate([
    (0, common_1.Post)('habit-templates'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createTemplate", null);
__decorate([
    (0, common_1.Patch)('habit-templates/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateTemplate", null);
__decorate([
    (0, common_1.Delete)('habit-templates/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteTemplate", null);
__decorate([
    (0, common_1.Get)('notices'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "listNotices", null);
__decorate([
    (0, common_1.Post)('notices'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createNotice", null);
__decorate([
    (0, common_1.Patch)('notices/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateNotice", null);
__decorate([
    (0, common_1.Delete)('notices/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteNotice", null);
__decorate([
    (0, common_1.Get)('system-config'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getConfig", null);
__decorate([
    (0, common_1.Patch)('system-config'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "patchConfig", null);
exports.AdminController = AdminController = __decorate([
    (0, common_1.Controller)('admin'),
    __metadata("design:paramtypes", [admin_auth_service_1.AdminAuthService,
        admin_data_service_1.AdminDataService,
        auth_service_1.AuthService,
        habits_service_1.HabitsService])
], AdminController);
//# sourceMappingURL=admin.controller.js.map