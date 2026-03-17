import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  InternalServerErrorException,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AiFeedbackService } from './ai-feedback.service';
import { JwtGuard } from './jwt.guard';
import { HabitsService, HabitDto, RecordDto } from './habits.service';

type ReqWithUser = Request & { userId: string };

@Controller('habits')
@UseGuards(JwtGuard)
export class HabitsController {
  constructor(
    private readonly habits: HabitsService,
    private readonly aiFeedbackService: AiFeedbackService,
  ) {}

  @Get()
  async list(@Req() req: ReqWithUser, @Query('archived') archived?: string) {
    return this.habits.list(req.userId, archived === 'true');
  }

  @Get(':id')
  async get(@Req() req: ReqWithUser, @Param('id') id: string) {
    const h = await this.habits.get(id, req.userId);
    if (!h) return { statusCode: 404, message: 'Not found' };
    return h;
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Req() req: ReqWithUser, @Body() body: Partial<HabitDto>) {
    try {
      return await this.habits.create(req.userId, {
        name: body.name!,
        category: body.category,
        goalType: body.goalType ?? 'completion',
        goalValue: body.goalValue,
        startDate: body.startDate!,
        colorHex: body.colorHex,
        iconName: body.iconName,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      throw new InternalServerErrorException(message);
    }
  }

  @Patch(':id')
  async update(
    @Req() req: ReqWithUser,
    @Param('id') id: string,
    @Body() body: Partial<HabitDto>,
  ) {
    const h = await this.habits.update(id, req.userId, body);
    if (!h) return { statusCode: 404, message: 'Not found' };
    return h;
  }

  @Delete(':id')
  async delete(@Req() req: ReqWithUser, @Param('id') id: string) {
    const ok = await this.habits.delete(id, req.userId);
    if (!ok) return { statusCode: 404, message: 'Not found' };
    return { ok: true };
  }

  @Get(':habitId/records')
  async listRecords(
    @Req() req: ReqWithUser,
    @Param('habitId') habitId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.habits.listRecords(habitId, req.userId, from, to);
  }

  @Post(':habitId/records')
  async addRecord(
    @Req() req: ReqWithUser,
    @Param('habitId') habitId: string,
    @Body() body: { recordDate: string; value?: number; completed: boolean },
  ) {
    const r = await this.habits.addRecord(habitId, req.userId, body);
    if (!r) return { statusCode: 404, message: 'Habit not found' };
    return r;
  }

  @Post(':habitId/records/:recordId/ai-feedback')
  async aiFeedback(
    @Req() req: ReqWithUser,
    @Param('habitId') habitId: string,
    @Param('recordId') recordId: string,
  ) {
    try {
      return await this.aiFeedbackService.requestFeedback(
        req.userId,
        habitId,
        recordId,
      );
    } catch (e) {
      return { statusCode: 404, message: (e as Error).message };
    }
  }
}
