import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtGuard } from '../habits/jwt.guard';
import { HabitsService } from '../habits/habits.service';

type ReqWithUser = Request & { userId: string };

@Controller('sync')
@UseGuards(JwtGuard)
export class SyncController {
  constructor(private readonly habits: HabitsService) {}

  @Get()
  async sync(@Req() req: ReqWithUser, @Query('since') _since?: string) {
    const { habits, records } = await this.habits.getSyncPayload(req.userId);
    return {
      users: [],
      habits,
      records,
    };
  }
}
