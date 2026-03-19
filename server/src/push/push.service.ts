import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities';

type Messaging = import('firebase-admin').messaging.Messaging;

@Injectable()
export class PushService {
  private messaging: Messaging | null = null;

  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {
    this.initFirebase();
  }

  private initFirebase(): void {
    try {
      const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
      const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      if (!path && !json) return;
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      if (admin.apps.length > 0) {
        this.messaging = admin.messaging();
        return;
      }
      let cred: object;
      if (json) {
        cred = JSON.parse(json);
      } else if (path) {
        const fs = require('fs');
        cred = JSON.parse(fs.readFileSync(path, 'utf8'));
      } else {
        return;
      }
      admin.initializeApp({ credential: admin.credential.cert(cred) });
      this.messaging = admin.messaging();
    } catch {
      this.messaging = null;
    }
  }

  /** 문의 답변 시 해당 사용자에게 푸시 알림 */
  async sendInquiryReplyNotification(userId: string, inquirySubject: string): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user?.fcmToken?.trim()) return;
    if (!this.messaging) return;
    const title = '문의에 답변이 등록되었습니다';
    const body = inquirySubject.length > 30 ? `${inquirySubject.slice(0, 30)}…` : inquirySubject;
    try {
      await this.messaging.send({
        token: user.fcmToken,
        notification: { title, body },
        data: { type: 'inquiry_reply', subject: inquirySubject },
        android: { priority: 'high' as const },
      });
    } catch {
      // 토큰 만료 등 시 무시
    }
  }

  /** 미달성 습관 리마인더(잠금 화면 Big Picture) 푸시 */
  async sendMissedHabitReminderNotification(params: {
    userId: string;
    missedHabitNames: string[];
  }): Promise<void> {
    const { userId, missedHabitNames } = params;
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user?.fcmToken?.trim()) return;
    if (!this.messaging) return;

    // Big Picture용 이미지 URL (서버가 제공하는 endpoint)
    const assetBaseUrl = process.env.PUBLIC_ASSET_BASE_URL ?? 'http://10.0.2.2:3000';
    const imageUrl = `${assetBaseUrl}/static/missed_habit.png`;

    const missedCount = missedHabitNames.length;
    const topName = missedHabitNames[0] ?? '습관';
    const title = '오늘도 놓친 습관이 있어요';
    const body =
      missedCount <= 1
        ? `${topName} 1일 미달성`
        : `${topName} 외 ${missedCount - 1}개 미달성`;

    try {
      await this.messaging.send({
        token: user.fcmToken,
        notification: { title, body },
        data: {
          type: 'missed_habit_reminder',
          missedCount: String(missedCount),
          topName,
        },
        android: {
          priority: 'high' as const,
          notification: {
            imageUrl,
          },
        },
      });
    } catch (e: unknown) {
      // 토큰 만료/네트워크 실패 등은 무시
      // eslint-disable-next-line no-console
      console.log('[PushService] sendMissedHabitReminderNotification failed', {
        userId,
        missedCount: missedHabitNames.length,
        err: e instanceof Error ? e.message : String(e),
      });
    }
  }
}
