"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.JwtGuard = void 0;
const common_1 = require("@nestjs/common");
const jwt_simple_1 = require("../auth/jwt-simple");
let JwtGuard = class JwtGuard {
    canActivate(context) {
        const req = context.switchToHttp().getRequest();
        const auth = req.headers.authorization;
        if (!auth?.startsWith('Bearer ')) {
            throw new common_1.UnauthorizedException('Missing or invalid Authorization');
        }
        try {
            const payload = (0, jwt_simple_1.verify)(auth.slice(7));
            req.userId = payload.sub;
            return true;
        }
        catch {
            throw new common_1.UnauthorizedException('Invalid token');
        }
    }
};
exports.JwtGuard = JwtGuard;
exports.JwtGuard = JwtGuard = __decorate([
    (0, common_1.Injectable)()
], JwtGuard);
//# sourceMappingURL=jwt.guard.js.map