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
exports.HabitRecord = void 0;
const typeorm_1 = require("typeorm");
let HabitRecord = class HabitRecord {
    id;
    habitId;
    recordDate;
    value;
    completed;
    createdAt;
    updatedAt;
};
exports.HabitRecord = HabitRecord;
__decorate([
    (0, typeorm_1.PrimaryColumn)(),
    __metadata("design:type", String)
], HabitRecord.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], HabitRecord.prototype, "habitId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], HabitRecord.prototype, "recordDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', nullable: true }),
    __metadata("design:type", Object)
], HabitRecord.prototype, "value", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: false }),
    __metadata("design:type", Boolean)
], HabitRecord.prototype, "completed", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ type: 'timestamptz' }),
    __metadata("design:type", Date)
], HabitRecord.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ type: 'timestamptz' }),
    __metadata("design:type", Date)
], HabitRecord.prototype, "updatedAt", void 0);
exports.HabitRecord = HabitRecord = __decorate([
    (0, typeorm_1.Entity)('habit_records')
], HabitRecord);
//# sourceMappingURL=habit-record.entity.js.map