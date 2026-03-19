import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { sign as signJwt } from './jwt-simple';
import { User, Habit, HabitRecord, AiFeedbackLog } from '../entities';
import { ConfigService } from '../config/config.service';

const DEFAULT_JWT_EXPIRES_SEC = 7 * 24 * 3600; // 7일

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Habit)
    private readonly habitRepo: Repository<Habit>,
    @InjectRepository(HabitRecord)
    private readonly recordRepo: Repository<HabitRecord>,
    @InjectRepository(AiFeedbackLog)
    private readonly feedbackRepo: Repository<AiFeedbackLog>,
    private readonly config: ConfigService,
  ) {}

  async loginGoogle(body: { idToken: string; email?: string; displayName?: string }) {
    const id = `google:${hashString(body.idToken).slice(0, 12)}`;
    return this.ensureUser(
      id,
      body.email?.trim() || null,
      body.displayName?.trim() || 'Google User',
    );
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
    } else {
      // 기존 사용자에게 이메일/표시명이 전달된 경우 연동 상태로 갱신
      if (email != null && email !== '') user.email = email;
      if (displayName != null && displayName !== '') user.displayName = displayName;
      await this.userRepo.save(user);
    }
    const expiresSecStr = await this.config.get('app_jwt_expires_seconds');
    const expiresSec = expiresSecStr ? parseInt(expiresSecStr, 10) : DEFAULT_JWT_EXPIRES_SEC;
    const accessToken = signJwt({ sub: user.id }, Number.isFinite(expiresSec) ? expiresSec : DEFAULT_JWT_EXPIRES_SEC);
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

  /** 회원 탈퇴: 연관 데이터 삭제 후 사용자 삭제 (정책: 탈퇴 즉시 삭제) */
  async deleteUser(userId: string): Promise<void> {
    await this.feedbackRepo.delete({ userId });
    const habits = await this.habitRepo.find({ where: { userId } });
    const habitIds = habits.map((h) => h.id);
    if (habitIds.length > 0) {
      await this.recordRepo
        .createQueryBuilder()
        .delete()
        .where('habitId IN (:...ids)', { ids: habitIds })
        .execute();
    }
    await this.habitRepo.delete({ userId });
    await this.userRepo.delete({ id: userId });
  }

  /** 앱에서 FCM 토큰 등록 */
  async updateFcmToken(userId: string, fcmToken: string | null): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) return;
    user.fcmToken = fcmToken && fcmToken.trim() !== '' ? fcmToken.trim() : null;
    await this.userRepo.save(user);
  }

  /** 관리자용: 앱 가입 사용자 목록 (가입일 포함) */
  async getAppUsers(): Promise<
    { id: string; email: string | null; displayName: string | null; createdAt: string }[]
  > {
    const list = await this.userRepo.find({ order: { createdAt: 'ASC' } });
    return list.map((u) => ({
      id: u.id,
      email: u.email,
      displayName: u.displayName,
      createdAt: u.createdAt.toISOString(),
    }));
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
