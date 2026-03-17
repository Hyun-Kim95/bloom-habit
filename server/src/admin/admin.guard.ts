import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { AdminAuthService } from './admin-auth.service';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly adminAuth: AdminAuthService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request>();
    const auth = req.headers.authorization;
    if (!auth?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid Authorization');
    }
    try {
      const payload = this.adminAuth.verifyAdminToken(auth.slice(7));
      (req as Request & { adminId: string }).adminId = payload.sub;
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired admin token');
    }
  }
}
