import { Body, Controller, Delete, Get, Patch, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
import { HabitsService } from '../habits/habits.service';

type ReqWithUser = Request & { userId: string };

const LEVEL_TITLES: Record<number, string> = {
  1: 'New Planter',
  2: 'Growing Seed',
  3: 'Budding Gardener',
};

@Controller('me')
@UseGuards(JwtGuard)
export class MeController {
  constructor(
    private readonly auth: AuthService,
    private readonly habits: HabitsService,
  ) {}

  @Patch()
  async updateMe(@Req() req: ReqWithUser, @Body() body: { fcmToken?: string | null }) {
    if (body.fcmToken !== undefined) {
      await this.auth.updateFcmToken(req.userId, body.fcmToken ?? null);
    }
    return { ok: true };
  }

  @Get('level')
  async getLevel(@Req() req: ReqWithUser) {
    const count = await this.habits.getCompletedCountLast7Days(req.userId);
    const level = count >= 7 ? 3 : count >= 3 ? 2 : 1;
    return { level, title: LEVEL_TITLES[level] };
  }

  @Delete()
  async deleteAccount(@Req() req: ReqWithUser) {
    await this.auth.deleteUser(req.userId);
    return { ok: true };
  }
}
