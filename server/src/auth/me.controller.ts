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
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';

type ReqWithUser = Request & { userId: string };

@Controller('me')
@UseGuards(JwtGuard)
export class MeController {
  constructor(private readonly auth: AuthService) {}

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
    const storedFileName = await this.auth.uploadAvatarFromPresignedToken(
      req.userId,
      decodeURIComponent(token),
      file,
    );
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return {
      avatarUrl: `${baseUrl}/static/avatars/${storedFileName}`,
    };
  }

  @Post('avatar/presign')
  async presignAvatarUpload(
    @Req() req: ReqWithUser,
    @Body() body: { fileName?: string; fileSize?: number; contentType?: string },
  ) {
    const presign = await this.auth.createAvatarUploadPresign(req.userId, body);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return {
      uploadUrl: `${baseUrl}/me/avatar/upload/${encodeURIComponent(presign.uploadToken)}`,
      publicUrl: `${baseUrl}/static/avatars/${presign.fileName}`,
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
