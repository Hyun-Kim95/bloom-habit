import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { sign as signJwt } from './jwt-simple';
import { User } from '../entities';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async loginGoogle(body: { idToken: string }) {
    const id = `google:${hashString(body.idToken).slice(0, 12)}`;
    return this.ensureUser(id, null, 'Google User');
  }

  async loginApple(body: {
    identityToken: string;
    email?: string;
    displayName?: string;
  }) {
    const id = `apple:${hashString(body.identityToken).slice(0, 12)}`;
    return this.ensureUser(
      id,
      body.email ?? null,
      body.displayName ?? 'Apple User',
    );
  }

  private async ensureUser(
    id: string,
    email: string | null,
    displayName: string | null,
  ) {
    let user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      user = this.userRepo.create({ id, email, displayName });
      await this.userRepo.save(user);
    }
    const accessToken = signJwt({ sub: user.id }, 7 * 24 * 3600);
    return {
      accessToken,
      refreshToken: null as string | null,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
    };
  }

  async logout(_userId: string) {}

  /** 관리자용: 앱 가입 사용자 목록 */
  async getAppUsers(): Promise<{ id: string; email: string | null; displayName: string | null }[]> {
    const list = await this.userRepo.find({ order: { createdAt: 'ASC' } });
    return list.map((u) => ({ id: u.id, email: u.email, displayName: u.displayName }));
  }
}

function hashString(s: string): string {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h << 5) - h + s.charCodeAt(i);
    h |= 0;
  }
  return Math.abs(h).toString(36);
}
