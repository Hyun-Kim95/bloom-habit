import { CanActivate, ExecutionContext } from '@nestjs/common';
import { AdminAuthService } from './admin-auth.service';
export declare class AdminGuard implements CanActivate {
    private readonly adminAuth;
    constructor(adminAuth: AdminAuthService);
    canActivate(context: ExecutionContext): boolean;
}
