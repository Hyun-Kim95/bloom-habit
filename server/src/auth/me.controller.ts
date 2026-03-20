import { Body, Controller, Delete, Get, Patch, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
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
    @Body() body: { fcmToken?: string | null; displayName?: string; avatarUrl?: string | null },
  ) {
    if (
      body.fcmToken !== undefined ||
      body.displayName !== undefined ||
      body.avatarUrl !== undefined
    ) {
      await this.auth.patchMe(req.userId, body);
    }
    return { ok: true };
  }

  @Delete()
  async deleteAccount(@Req() req: ReqWithUser) {
    await this.auth.deleteUser(req.userId);
    return { ok: true };
  }
}
