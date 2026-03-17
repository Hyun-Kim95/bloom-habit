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
exports.SyncController = void 0;
const common_1 = require("@nestjs/common");
const jwt_guard_1 = require("../habits/jwt.guard");
const habits_service_1 = require("../habits/habits.service");
let SyncController = class SyncController {
    habits;
    constructor(habits) {
        this.habits = habits;
    }
    async sync(req, _since) {
        const { habits, records } = await this.habits.getSyncPayload(req.userId);
        return {
            users: [],
            habits,
            records,
        };
    }
};
exports.SyncController = SyncController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('since')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "sync", null);
exports.SyncController = SyncController = __decorate([
    (0, common_1.Controller)('sync'),
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    __metadata("design:paramtypes", [habits_service_1.HabitsService])
], SyncController);
//# sourceMappingURL=sync.controller.js.map