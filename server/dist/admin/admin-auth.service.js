"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminAuthService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const crypto = __importStar(require("crypto"));
const jwt_simple_1 = require("../auth/jwt-simple");
const entities_1 = require("../entities");
const uuid_1 = require("uuid");
const ADMIN_SECRET = process.env.ADMIN_JWT_SECRET ?? 'bloom-habit-admin-secret';
function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}
let AdminAuthService = class AdminAuthService {
    adminUserRepo;
    constructor(adminUserRepo) {
        this.adminUserRepo = adminUserRepo;
    }
    async onModuleInit() {
        const email = process.env.ADMIN_EMAIL ?? 'admin@bloom.local';
        const password = process.env.ADMIN_PASSWORD ?? 'admin123';
        let admin = await this.adminUserRepo.findOne({ where: { email } });
        if (!admin) {
            admin = this.adminUserRepo.create({
                id: `admin-${(0, uuid_1.v4)()}`,
                email,
                passwordHash: hashPassword(password),
            });
            await this.adminUserRepo.save(admin);
        }
    }
    async login(email, password) {
        const admin = await this.adminUserRepo.findOne({ where: { email } });
        if (!admin || admin.passwordHash !== hashPassword(password)) {
            throw new common_1.UnauthorizedException('Invalid email or password');
        }
        const token = (0, jwt_simple_1.sign)({ sub: admin.id, role: 'admin' }, 8 * 3600, ADMIN_SECRET);
        return { accessToken: token };
    }
    verifyAdminToken(token) {
        const payload = (0, jwt_simple_1.verify)(token, ADMIN_SECRET);
        if (payload.role !== 'admin')
            throw new common_1.UnauthorizedException('Not admin');
        return payload;
    }
};
exports.AdminAuthService = AdminAuthService;
exports.AdminAuthService = AdminAuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(entities_1.AdminUser)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], AdminAuthService);
//# sourceMappingURL=admin-auth.service.js.map