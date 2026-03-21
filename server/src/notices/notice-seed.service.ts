import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Notice } from '../entities';

/** DB에 공지가 하나도 없을 때만 삽입하는 샘플(개발·데모용). */
const SAMPLE_NOTICES: { title: string; body: string; publishedAt: Date }[] = [
  {
    title: '이메일 등록·인증 기능 안내',
    body:
      '계정 관리에서 이메일을 직접 등록하고 인증할 수 있습니다.\n' +
      '인증을 완료하면 향후 계정 복구·찾기 등에 활용할 수 있어요.\n' +
      '소셜 로그인만 사용 중이신 분도 이메일이 없다면 등록을 권장드립니다.',
    publishedAt: new Date('2026-03-18T02:00:00.000Z'),
  },
  {
    title: '공지사항을 앱에서 확인하세요',
    body:
      '설정 > 공지사항에서 서비스 안내와 업데이트 소식을 확인할 수 있습니다.\n' +
      '앞으로도 이용에 참고 부탁드립니다.',
    publishedAt: new Date('2026-03-10T06:00:00.000Z'),
  },
  {
    title: '습관 통계·히트맵 안내',
    body:
      '통계 화면에서 주·월 단위로 달성률을 확인할 수 있고,\n' +
      '홈에서는 완료 히트맵으로 한눈에 기록을 살펴볼 수 있어요.\n' +
      '꾸준한 기록에 도움이 되시길 바랍니다.',
    publishedAt: new Date('2026-02-28T09:00:00.000Z'),
  },
  {
    title: '푸시 알림 설정 안내',
    body:
      '기기 설정과 앱 알림 설정에서 리마인더 알림을 켜 두시면\n' +
      '습관 시간에 맞춰 알림을 받을 수 있습니다.\n' +
      '방해가 된다면 습관별로 알림을 끄거나 시간을 조정해 보세요.',
    publishedAt: new Date('2026-02-15T08:00:00.000Z'),
  },
  {
    title: 'Bloom Habit 이용 안내',
    body:
      'Bloom Habit은 작은 습관을 매일 기록하고 통계로 확인할 수 있는 서비스입니다.\n' +
      'Google·카카오·네이버 계정으로 간편하게 시작할 수 있어요.\n' +
      '문의는 앱 내 문의하기를 이용해 주세요.',
    publishedAt: new Date('2026-02-01T10:00:00.000Z'),
  },
];

@Injectable()
export class NoticeSeedService implements OnModuleInit {
  private readonly logger = new Logger(NoticeSeedService.name);

  constructor(
    @InjectRepository(Notice)
    private readonly noticeRepo: Repository<Notice>,
  ) {}

  async onModuleInit(): Promise<void> {
    const count = await this.noticeRepo.count();
    if (count > 0) return;
    for (const row of SAMPLE_NOTICES) {
      await this.noticeRepo.save(
        this.noticeRepo.create({
          id: `n-${uuidv4()}`,
          title: row.title,
          body: row.body,
          publishedAt: row.publishedAt,
        }),
      );
    }
    this.logger.log(`샘플 공지 ${SAMPLE_NOTICES.length}건을 등록했습니다.`);
  }
}
