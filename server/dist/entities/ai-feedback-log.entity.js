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
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiFeedbackLog = void 0;
const typeorm_1 = require("typeorm");
let AiFeedbackLog = class AiFeedbackLog {
    id;
    userId;
    habitId;
    recordDate;
    recordId;
    responseText;
    createdAt;
};
exports.AiFeedbackLog = AiFeedbackLog;
__decorate([
    (0, typeorm_1.PrimaryColumn)(),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "habitId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "recordDate", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "recordId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text' }),
    __metadata("design:type", String)
], AiFeedbackLog.prototype, "responseText", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz' }),
    __metadata("design:type", Date)
], AiFeedbackLog.prototype, "createdAt", void 0);
exports.AiFeedbackLog = AiFeedbackLog = __decorate([
    (0, typeorm_1.Entity)('ai_feedback_logs')
], AiFeedbackLog);
//# sourceMappingURL=ai-feedback-log.entity.js.map