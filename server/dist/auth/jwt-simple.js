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
Object.defineProperty(exports, "__esModule", { value: true });
exports.sign = sign;
exports.verify = verify;
const crypto = __importStar(require("crypto"));
const defaultSecret = process.env.JWT_SECRET ?? 'bloom-habit-dev-secret';
function signWithSecret(payload, expiresInSeconds, secret) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const exp = Math.floor(Date.now() / 1000) + expiresInSeconds;
    const payloadWithExp = { ...payload, exp };
    const b64 = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
    const signature = crypto
        .createHmac('sha256', secret)
        .update(`${b64(header)}.${b64(payloadWithExp)}`)
        .digest('base64url');
    return `${b64(header)}.${b64(payloadWithExp)}.${signature}`;
}
function sign(payload, expiresInSeconds, secret) {
    return signWithSecret(payload, expiresInSeconds, secret ?? defaultSecret);
}
function verifyWithSecret(token, secret) {
    const parts = token.split('.');
    if (parts.length !== 3)
        throw new Error('Invalid token');
    const expectedSig = crypto
        .createHmac('sha256', secret)
        .update(`${parts[0]}.${parts[1]}`)
        .digest('base64url');
    if (parts[2] !== expectedSig)
        throw new Error('Invalid signature');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (payload.exp && payload.exp < Date.now() / 1000)
        throw new Error('Token expired');
    return { sub: payload.sub, role: payload.role };
}
function verify(token, secret) {
    return verifyWithSecret(token, secret ?? defaultSecret);
}
//# sourceMappingURL=jwt-simple.js.map