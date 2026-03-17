import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { verify } from '../auth/jwt-simple';

@Injectable()
export class JwtGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request>();
    const auth = req.headers.authorization;
    if (!auth?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid Authorization');
    }
    try {
      const payload = verify(auth.slice(7));
      (req as Request & { userId: string }).userId = payload.sub;
      return true;
    } catch {
      throw new UnauthorizedException('Invalid token');
    }
  }
}
