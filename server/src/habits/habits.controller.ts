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
import { ConfigService } from '../config/config.service';
import { AiFeedbackService } from './ai-feedback.service';
import { JwtGuard } from './jwt.guard';
import { HabitsService, HabitDto, RecordDto } from './habits.service';

type ReqWithUser = Request & { userId: string };

const HABIT_CATEGORIES_KEY = 'habit_categories';

@Controller('habits')
@UseGuards(JwtGuard)
export class HabitsController {
  constructor(
    private readonly habits: HabitsService,
    private readonly aiFeedbackService: AiFeedbackService,
    private readonly config: ConfigService,
  ) {}

  /** 앱에서 습관 생성 시 선택할 카테고리 목록 (관리자에서 설정) */
  @Get('categories')
  async categories(): Promise<string[]> {
    const raw = await this.config.get(HABIT_CATEGORIES_KEY);
    if (!raw || raw.trim() === '') return [];
    try {
      const arr = JSON.parse(raw) as unknown;
      return Array.isArray(arr) ? arr.filter((x): x is string => typeof x === 'string') : [];
    } catch {
      return [];
    }
  }

  /** 앱 통계용: 내 최근 AI 피드백 목록 */
  @Get('ai-feedback')
  async listAiFeedback(@Req() req: ReqWithUser, @Query('limit') limit?: string) {
    const n = limit ? parseInt(limit, 10) : 30;
    const take = Number.isFinite(n) && n >= 1 && n <= 100 ? n : 30;
    return this.aiFeedbackService.listForUser(req.userId, take);
  }

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

  @Patch(':id/archive')
  async archive(@Req() req: ReqWithUser, @Param('id') id: string) {
    const h = await this.habits.archive(id, req.userId);
    if (!h) return { statusCode: 404, message: 'Not found' };
    return h;
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

  @Patch(':habitId/records/:recordId')
  async updateRecord(
    @Req() req: ReqWithUser,
    @Param('habitId') habitId: string,
    @Param('recordId') recordId: string,
    @Body() body: { completed?: boolean; value?: number },
  ) {
    const r = await this.habits.updateRecord(habitId, recordId, req.userId, body);
    if (!r) return { statusCode: 404, message: 'Not found' };
    return r;
  }

  @Delete(':habitId/records/:recordId')
  async deleteRecord(
    @Req() req: ReqWithUser,
    @Param('habitId') habitId: string,
    @Param('recordId') recordId: string,
  ) {
    const ok = await this.habits.deleteRecord(habitId, recordId, req.userId);
    if (!ok) return { statusCode: 404, message: 'Not found' };
    return { ok: true };
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
