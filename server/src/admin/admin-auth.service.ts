import { Injectable, UnauthorizedException } from '@nestjs/common';
import { OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as crypto from 'crypto';
import { sign as signJwt, verify as verifyJwt } from '../auth/jwt-simple';
import { AdminUser } from '../entities';
import { v4 as uuidv4 } from 'uuid';

const ADMIN_SECRET = process.env.ADMIN_JWT_SECRET ?? 'bloom-habit-admin-secret';

function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password).digest('hex');
}

@Injectable()
export class AdminAuthService implements OnModuleInit {
  constructor(
    @InjectRepository(AdminUser)
    private readonly adminUserRepo: Repository<AdminUser>,
  ) {}

  async onModuleInit() {
    const email = process.env.ADMIN_EMAIL ?? 'admin@bloom.local';
    const password = process.env.ADMIN_PASSWORD ?? 'admin123';
    let admin = await this.adminUserRepo.findOne({ where: { email } });
    if (!admin) {
      admin = this.adminUserRepo.create({
        id: `admin-${uuidv4()}`,
        email,
        passwordHash: hashPassword(password),
      });
      await this.adminUserRepo.save(admin);
    }
  }

  async login(email: string, password: string): Promise<{ accessToken: string }> {
    const admin = await this.adminUserRepo.findOne({ where: { email } });
    if (!admin || admin.passwordHash !== hashPassword(password)) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const token = signJwt(
      { sub: admin.id, role: 'admin' },
      8 * 3600,
      ADMIN_SECRET,
    );
    return { accessToken: token };
  }

  verifyAdminToken(token: string): { sub: string } {
    const payload = verifyJwt(token, ADMIN_SECRET) as { sub: string; role?: string };
    if (payload.role !== 'admin') throw new UnauthorizedException('Not admin');
    return payload;
  }
}
