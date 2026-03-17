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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const jwt_simple_1 = require("./jwt-simple");
const entities_1 = require("../entities");
let AuthService = class AuthService {
    userRepo;
    constructor(userRepo) {
        this.userRepo = userRepo;
    }
    async loginGoogle(body) {
        const id = `google:${hashString(body.idToken).slice(0, 12)}`;
        return this.ensureUser(id, null, 'Google User');
    }
    async loginApple(body) {
        const id = `apple:${hashString(body.identityToken).slice(0, 12)}`;
        return this.ensureUser(id, body.email ?? null, body.displayName ?? 'Apple User');
    }
    async ensureUser(id, email, displayName) {
        let user = await this.userRepo.findOne({ where: { id } });
        if (!user) {
            user = this.userRepo.create({ id, email, displayName });
            await this.userRepo.save(user);
        }
        const accessToken = (0, jwt_simple_1.sign)({ sub: user.id }, 7 * 24 * 3600);
        return {
            accessToken,
            refreshToken: null,
            user: {
                id: user.id,
                email: user.email,
                displayName: user.displayName,
            },
        };
    }
    async logout(_userId) { }
    async getAppUsers() {
        const list = await this.userRepo.find({ order: { createdAt: 'ASC' } });
        return list.map((u) => ({ id: u.id, email: u.email, displayName: u.displayName }));
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(entities_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], AuthService);
function hashString(s) {
    let h = 0;
    for (let i = 0; i < s.length; i++) {
        h = (h << 5) - h + s.charCodeAt(i);
        h |= 0;
    }
    return Math.abs(h).toString(36);
}
//# sourceMappingURL=auth.service.js.map