"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const auth_module_1 = require("../auth/auth.module");
const habits_module_1 = require("../habits/habits.module");
const admin_auth_service_1 = require("./admin-auth.service");
const admin_controller_1 = require("./admin.controller");
const admin_data_service_1 = require("./admin-data.service");
const admin_guard_1 = require("./admin.guard");
const entities_1 = require("../entities");
let AdminModule = class AdminModule {
};
exports.AdminModule = AdminModule;
exports.AdminModule = AdminModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([entities_1.AdminUser, entities_1.HabitTemplate, entities_1.Notice, entities_1.SystemConfig]),
            auth_module_1.AuthModule,
            habits_module_1.HabitsModule,
        ],
        controllers: [admin_controller_1.AdminController],
        providers: [admin_auth_service_1.AdminAuthService, admin_data_service_1.AdminDataService, admin_guard_1.AdminGuard],
    })
], AdminModule);
//# sourceMappingURL=admin.module.js.map