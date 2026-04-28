import {
  Body,
  Controller,
  Delete,
  Get,
  Post,
  Put,
  Param,
  Patch,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { Repository } from 'typeorm';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
import { Inquiry, Notice, NoticeRead } from '../entities';
import { InquiriesService } from '../inquiries/inquiries.service';

type ReqWithUser = Request & { userId: string };

@Controller('me')
@UseGuards(JwtGuard)
export class MeController {
  constructor(
    private readonly auth: AuthService,
    private readonly inquiriesService: InquiriesService,
    @InjectRepository(Notice)
    private readonly noticeRepo: Repository<Notice>,
  ) {}

  @Get()
  async getMe(@Req() req: ReqWithUser) {
    return this.auth.getMe(req.userId);
  }

  @Patch()
  async updateMe(
    @Req() req: ReqWithUser,
    @Body()
    body: {
      fcmToken?: string | null;
      displayName?: string;
      avatarUrl?: string | null;
      email?: string;
    },
  ) {
    if (
      body.fcmToken !== undefined ||
      body.displayName !== undefined ||
      body.avatarUrl !== undefined ||
      body.email !== undefined
    ) {
      await this.auth.patchMe(req.userId, body);
    }
    return { ok: true };
  }

  @Get('unread-summary')
  async unreadSummary(@Req() req: ReqWithUser) {
    const inquiryUnreadCount = await this.inquiriesService.countUnreadAnsweredByUser(req.userId);
    const now = new Date();
    const row = await this.noticeRepo
      .createQueryBuilder('n')
      .leftJoin(
        NoticeRead,
        'nr',
        'nr.noticeId = n.id AND nr.userId = :userId',
        { userId: req.userId },
      )
      .select('COUNT(1)', 'count')
      .where('n.publishedAt IS NOT NULL')
      .andWhere('n.publishedAt <= :now', { now })
      .andWhere('n.isNotice = true')
      .andWhere('n.isPublic = true')
      .andWhere('(n.displayStartAt IS NULL OR n.displayStartAt <= :now)', { now })
      .andWhere('(n.displayEndAt IS NULL OR n.displayEndAt >= :now)', { now })
      .andWhere('nr.id IS NULL')
      .getRawOne<{ count: string }>();
    const noticeUnreadCount = Number(row?.count ?? 0);
    return {
      noticeUnreadCount,
      inquiryUnreadCount,
      hasUnread: noticeUnreadCount > 0 || inquiryUnreadCount > 0,
    };
  }

  @Put('avatar/upload/:token')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadAvatar(
    @Req() req: ReqWithUser,
    @Param('token') token: string,
    @UploadedFile()
    file: any,
  ) {
    console.log(
      `[avatar-upload] user=${req.userId} mime=${file?.mimetype ?? 'none'} size=${file?.size ?? 0} name=${file?.originalname ?? 'none'}`,
    );
    const storedFileName = await this.auth.uploadAvatarFromPresignedToken(
      req.userId,
      decodeURIComponent(token),
      file,
    );
    return {
      avatarUrl: `/static/avatars/${storedFileName}`,
    };
  }

  @Post('avatar/presign')
  async presignAvatarUpload(
    @Req() req: ReqWithUser,
    @Body() body: { fileName?: string; fileSize?: number; contentType?: string },
  ) {
    const presign = await this.auth.createAvatarUploadPresign(req.userId, body);
    return {
      uploadUrl: `/me/avatar/upload/${encodeURIComponent(presign.uploadToken)}`,
      publicUrl: `/static/avatars/${presign.fileName}`,
    };
  }

  @Delete()
  async deleteAccount(
    @Req() req: ReqWithUser,
    @Body() body: { reason?: string },
  ) {
    await this.auth.deactivateSelf(req.userId, body.reason ?? '');
    return { ok: true };
  }
}
