import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { sign as signJwt } from './jwt-simple';
import { User, Habit, HabitRecord } from '../entities';
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
    private readonly config: ConfigService,
  ) {}

  async loginGoogle(body: {
    idToken: string;
    email?: string;
    displayName?: string;
    avatarUrl?: string | null;
  }) {
    const stableSub = extractJwtSub(body.idToken);
    const id = stableSub
      ? `google:${stableSub}`
      : `google:${hashString(body.idToken).slice(0, 12)}`;
    const avatarIn = 'avatarUrl' in body ? normalizeAvatarUrl(body.avatarUrl) : undefined;
    return this.ensureUser(
      id,
      'google',
      body.email?.trim() || null,
      body.displayName?.trim() || 'Google User',
      avatarIn,
    );
  }

  async loginKakao(body: { accessToken: string }) {
    const profile = await fetchKakaoProfile(body.accessToken);
    const id = `kakao:${profile.id}`;
    return this.ensureUser(
      id,
      'kakao',
      profile.email,
      profile.displayName ?? 'Kakao User',
      profile.avatarUrl,
    );
  }

  async loginNaver(body: { accessToken: string }) {
    const profile = await fetchNaverProfile(body.accessToken);
    const id = `naver:${profile.id}`;
    return this.ensureUser(
      id,
      'naver',
      profile.email,
      profile.displayName ?? 'Naver User',
      profile.avatarUrl,
    );
  }

  /**
   * @param avatarUpdate 소셜 프로필 이미지 동기화값. undefined면 기존 avatarUrl 유지, null이면 제거.
   */
  private async ensureUser(
    id: string,
    provider: 'google' | 'apple' | 'kakao' | 'naver',
    email: string | null,
    displayName: string | null,
    avatarUpdate?: string | null,
  ) {
    const normalizedEmail = normalizeEmail(email);
    if (normalizedEmail != null) {
      const inactiveSameProviderUser = await this.findInactiveUserByEmailAndProvider(
        normalizedEmail,
        provider,
      );
      if (inactiveSameProviderUser != null && inactiveSameProviderUser.id != id) {
        throw new BadRequestException(
          '비활성화된 동일 플랫폼 계정이 있습니다. 관리자에게 계정 활성화를 요청하세요.',
        );
      }
      const activeEmailUser = await this.findActiveUserByEmail(normalizedEmail);
      if (activeEmailUser != null && activeEmailUser.id != id) {
        const existingProvider =
          activeEmailUser.authProvider ?? authProviderFromUserId(activeEmailUser.id);
        if (existingProvider != provider) {
          throw new BadRequestException('이미 다른 로그인 방식으로 가입된 이메일입니다.');
        }
      }
    }

    let user = await this.userRepo.findOne({ where: { id } });
    // OAuth로 계산한 id가 예전 방식(예: Google 해시 폴백)과 달라지면 findOne이 실패해
    // 동일 이메일·동일 provider로 이미 있는 계정(재활성화 포함)과 매칭한다.
    if (!user && normalizedEmail != null) {
      user = await this.findUserByEmailAndProviderForLogin(normalizedEmail, provider);
    }
    if (!user) {
      if (normalizedEmail == null) {
        throw new BadRequestException(
          '이메일이 필요합니다. 소셜 계정에서 이메일 제공에 동의했는지 확인하거나, 이메일을 제공하는 계정으로 로그인해 주세요.',
        );
      }
      const avatarUrl = avatarUpdate !== undefined ? avatarUpdate : null;
      user = this.userRepo.create({
        id,
        authProvider: provider,
        email: normalizedEmail,
        emailVerifiedAt: new Date(),
        displayName,
        avatarUrl,
        isActive: true,
      });
      await this.userRepo.save(user);
    } else {
      if (!user.isActive) {
        throw new BadRequestException('비활성화된 계정입니다. 관리자에게 문의하세요.');
      }
      // 기존 사용자에게 이메일/표시명이 전달된 경우 연동 상태로 갱신
      user.authProvider = provider;
      if (normalizedEmail != null) {
        user.email = normalizedEmail;
        user.emailVerifiedAt = new Date();
      }
      if (displayName != null && displayName !== '') user.displayName = displayName;
      if (avatarUpdate !== undefined) {
        user.avatarUrl = avatarUpdate;
      }
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
        avatarUrl: user.avatarUrl,
        authProvider: user.authProvider ?? authProviderFromUserId(user.id),
      },
    };
  }

  async getMe(userId: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.isActive) throw new BadRequestException('비활성화된 계정입니다.');
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      authProvider: user.authProvider ?? authProviderFromUserId(user.id),
      createdAt: user.createdAt.toISOString(),
    };
  }

  async patchMe(
    userId: string,
    body: {
      fcmToken?: string | null;
      displayName?: string;
      avatarUrl?: string | null;
      email?: string;
    },
  ): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.isActive) throw new BadRequestException('비활성화된 계정입니다.');

    if (body.fcmToken !== undefined) {
      user.fcmToken =
        body.fcmToken && String(body.fcmToken).trim() !== ''
          ? String(body.fcmToken).trim()
          : null;
    }
    if (body.displayName !== undefined) {
      const d = String(body.displayName).trim();
      if (d.length > 20) throw new BadRequestException('닉네임은 20자 이하여야 합니다.');
      user.displayName = d.length > 0 ? d : null;
    }
    if (body.avatarUrl !== undefined) {
      if (body.avatarUrl === null || String(body.avatarUrl).trim() === '') {
        user.avatarUrl = null;
      } else {
        const u = String(body.avatarUrl).trim();
        if (u.length > 2048) throw new BadRequestException('avatarUrl이 너무 깁니다.');
        if (!/^https?:\/\//i.test(u)) throw new BadRequestException('avatarUrl은 http(s) URL이어야 합니다.');
        user.avatarUrl = u;
      }
    }
    if (body.email !== undefined) {
      const normalized = normalizeEmail(body.email);
      if (normalized == null || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
        throw new BadRequestException('유효한 이메일 주소를 입력해 주세요.');
      }
      if (user.email != null) {
        if (normalizeEmail(user.email) === normalized) {
          // no-op
        } else {
          throw new BadRequestException('이미 등록된 이메일이 있습니다. 변경이 필요하면 문의해 주세요.');
        }
      } else {
        const other = await this.findActiveUserByEmail(normalized, userId);
        if (other != null) {
          throw new ConflictException('이미 다른 계정에서 사용 중인 이메일입니다.');
        }
        user.email = normalized;
        user.emailVerifiedAt = new Date();
      }
    }
    await this.userRepo.save(user);
  }

  async logout(_userId: string) {}

  /**
   * 회원 탈퇴: 계정 비활성화 + 사유 저장.
   * 비활성화 시점부터 INACTIVE_USER_RETENTION_DAYS(기본 365일) 경과 후 배치가 관련 데이터·user 행을 삭제한다.
   */
  async deactivateSelf(userId: string, reason: string): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    const r = reason.trim();
    if (r.length === 0 || r.length > 500) {
      throw new BadRequestException('탈퇴 사유는 1~500자여야 합니다.');
    }
    user.isActive = false;
    user.deactivatedAt = new Date();
    user.deactivationReason = r;
    user.deactivatedBy = 'self';
    await this.userRepo.save(user);
  }

  /** @deprecated patchMe 사용 */
  async updateFcmToken(userId: string, fcmToken: string | null): Promise<void> {
    await this.patchMe(userId, { fcmToken });
  }

  /** 관리자용: 앱 가입 사용자 목록 (가입일 포함) */
  async getAppUsers(): Promise<
    {
      id: string;
      email: string | null;
      authProvider: 'google' | 'apple' | 'kakao' | 'naver' | 'unknown';
      displayName: string | null;
      createdAt: string;
      isActive: boolean;
      deactivatedAt: string | null;
      deactivationReason: string | null;
      deactivatedBy: 'self' | 'admin' | null;
    }[]
  > {
    const list = await this.userRepo.find({ order: { createdAt: 'ASC' } });
    return list.map((u) => ({
      id: u.id,
      email: u.email,
      authProvider: u.authProvider ?? authProviderFromUserId(u.id),
      displayName: u.displayName,
      createdAt: u.createdAt.toISOString(),
      isActive: u.isActive,
      deactivatedAt: u.deactivatedAt?.toISOString() ?? null,
      deactivationReason: u.deactivationReason ?? null,
      deactivatedBy: u.deactivatedBy ?? null,
    }));
  }

  async setUserActive(userId: string, isActive: boolean, reason?: string): Promise<boolean> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) return false;
    user.isActive = isActive;
    if (isActive) {
      const normalizedEmail = normalizeEmail(user.email);
      if (normalizedEmail != null) {
        const other = await this.findActiveUserByEmail(normalizedEmail, user.id);
        if (other != null) {
          const selfProvider = user.authProvider ?? authProviderFromUserId(user.id);
          const otherProvider = other.authProvider ?? authProviderFromUserId(other.id);
          if (selfProvider != otherProvider) {
            throw new BadRequestException('동일 이메일로 다른 로그인 방식의 활성 계정이 있어 활성화할 수 없습니다.');
          }
        }
      }
      user.deactivatedAt = null;
      user.deactivationReason = null;
      user.deactivatedBy = null;
    } else {
      const r = (reason ?? '').trim();
      if (r.length === 0 || r.length > 500) {
        throw new BadRequestException('비활성화 사유는 1~500자여야 합니다.');
      }
      user.deactivatedAt = new Date();
      user.deactivationReason = r;
      user.deactivatedBy = 'admin';
    }
    await this.userRepo.save(user);
    return true;
  }

  /** 동일 이메일 + 동일 소셜 provider로 가입한 기존 행 (id 불일치 시 재매칭용). */
  private async findUserByEmailAndProviderForLogin(
    email: string,
    provider: 'google' | 'apple' | 'kakao' | 'naver',
  ): Promise<User | null> {
    return this.userRepo
      .createQueryBuilder('u')
      .where('LOWER(u.email) = LOWER(:email)', { email })
      .andWhere('(u.authProvider = :provider OR u.id LIKE :prefix)', {
        provider,
        prefix: `${provider}:%`,
      })
      .orderBy('u.createdAt', 'ASC')
      .getOne();
  }

  private async findActiveUserByEmail(email: string, excludeId?: string): Promise<User | null> {
    const qb = this.userRepo
      .createQueryBuilder('u')
      .where('LOWER(u.email) = LOWER(:email)', { email })
      .andWhere('u.isActive = true');
    if (excludeId != null) qb.andWhere('u.id <> :excludeId', { excludeId });
    return qb.orderBy('u.createdAt', 'ASC').getOne();
  }

  private async findInactiveUserByEmailAndProvider(
    email: string,
    provider: 'google' | 'apple' | 'kakao' | 'naver',
  ): Promise<User | null> {
    return this.userRepo
      .createQueryBuilder('u')
      .where('LOWER(u.email) = LOWER(:email)', { email })
      .andWhere('u.isActive = false')
      .andWhere('(u.authProvider = :provider OR u.id LIKE :providerPrefix)', {
        provider,
        providerPrefix: `${provider}:%`,
      })
      .orderBy('u.createdAt', 'ASC')
      .getOne();
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

function authProviderFromUserId(id: string): 'google' | 'apple' | 'kakao' | 'naver' | 'unknown' {
  if (id.startsWith('google:')) return 'google';
  if (id.startsWith('apple:')) return 'apple';
  if (id.startsWith('kakao:')) return 'kakao';
  if (id.startsWith('naver:')) return 'naver';
  return 'unknown';
}

function normalizeEmail(email: string | null | undefined): string | null {
  if (email == null) return null;
  const v = email.trim().toLowerCase();
  return v.length === 0 ? null : v;
}

/** undefined: 필드 생략(구 클라). null/문자열: 구글 프로필 동기화 */
function normalizeAvatarUrl(v: string | null | undefined): string | null | undefined {
  if (v === undefined) return undefined;
  if (v === null || String(v).trim() === '') return null;
  const s = String(v).trim();
  if (s.length > 2048) return null;
  if (!/^https?:\/\//i.test(s)) return null;
  return s;
}

function extractJwtSub(token: string): string | null {
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const payloadRaw = parts[1]
      .replace(/-/g, '+')
      .replace(/_/g, '/')
      .padEnd(Math.ceil(parts[1].length / 4) * 4, '=');
    const payloadJson = Buffer.from(payloadRaw, 'base64').toString('utf8');
    const payload = JSON.parse(payloadJson) as { sub?: unknown };
    if (typeof payload.sub !== 'string' || payload.sub.trim() === '') return null;
    // Keep only safe characters for PK column.
    return payload.sub.trim().replace(/[^a-zA-Z0-9:_-]/g, '');
  } catch {
    return null;
  }
}

async function fetchKakaoProfile(accessToken: string): Promise<{
  id: string;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}> {
  const token = accessToken.trim();
  if (token === '') throw new BadRequestException('Kakao accessToken is required');
  const res = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new BadRequestException('Kakao token verification failed');
  const data = (await res.json()) as {
    id?: number | string;
    kakao_account?: {
      email?: string;
      profile?: { nickname?: string; profile_image_url?: string };
    };
  };
  const id = data.id != null ? String(data.id) : '';
  if (id.trim() == '') throw new BadRequestException('Invalid Kakao profile');
  return {
    id,
    email: data.kakao_account?.email?.trim() || null,
    displayName: data.kakao_account?.profile?.nickname?.trim() || null,
    avatarUrl: normalizeAvatarUrl(data.kakao_account?.profile?.profile_image_url) ?? null,
  };
}

async function fetchNaverProfile(accessToken: string): Promise<{
  id: string;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}> {
  const token = accessToken.trim();
  if (token === '') throw new BadRequestException('Naver accessToken is required');
  const res = await fetch('https://openapi.naver.com/v1/nid/me', {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new BadRequestException('Naver token verification failed');
  const data = (await res.json()) as {
    response?: {
      id?: string;
      email?: string;
      name?: string;
      nickname?: string;
      profile_image?: string;
    };
  };
  const id = data.response?.id?.trim() ?? '';
  if (id == '') throw new BadRequestException('Invalid Naver profile');
  return {
    id,
    email: data.response?.email?.trim() || null,
    displayName: data.response?.name?.trim() || data.response?.nickname?.trim() || null,
    avatarUrl: normalizeAvatarUrl(data.response?.profile_image) ?? null,
  };
}
