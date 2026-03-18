import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { HabitsService } from '../habits/habits.service';
import { AdminAuthService } from './admin-auth.service';
import { AdminDataService, HabitTemplateDto, InquiryAdminDto, NoticeDto } from './admin-data.service';
import { AdminGuard } from './admin.guard';
import { AdminStatsService } from './admin-stats.service';

@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminAuth: AdminAuthService,
    private readonly adminData: AdminDataService,
    private readonly adminStats: AdminStatsService,
    private readonly auth: AuthService,
    private readonly habits: HabitsService,
  ) {}

  @Post('auth/login')
  async login(@Body() body: { email: string; password: string }) {
    return this.adminAuth.login(body.email, body.password);
  }

  @Get('users')
  @UseGuards(AdminGuard)
  async users() {
    const list = await this.auth.getAppUsers();
    const userIds = list.map((u) => u.id);
    const statsMap = await this.habits.getUserStatsMap(userIds);
    return list.map((u) => {
      const s = statsMap[u.id] ?? { habitCount: 0, totalRecords: 0, completedRecords: 0 };
      const completionRatePercent =
        s.totalRecords > 0 ? Math.round((s.completedRecords / s.totalRecords) * 100) : null;
      return {
        id: u.id,
        email: u.email,
        displayName: u.displayName,
        createdAt: u.createdAt,
        habitCount: s.habitCount,
        totalRecords: s.totalRecords,
        completedRecords: s.completedRecords,
        completionRatePercent,
      };
    });
  }

  @Get('stats')
  @UseGuards(AdminGuard)
  async stats() {
    const users = await this.auth.getAppUsers();
    const counts = await this.habits.getTotalCounts();
    return {
      totalUsers: users.length,
      totalHabits: counts.totalHabits,
      totalRecords: counts.totalRecords,
    };
  }

  @Get('stats/over-time')
  @UseGuards(AdminGuard)
  async statsOverTime(@Query('from') from?: string, @Query('to') to?: string) {
    const toDate = new Date();
    const fromDate = new Date(toDate);
    fromDate.setDate(fromDate.getDate() - 90);
    const fromStr = from ?? fromDate.toISOString().slice(0, 10);
    const toStr = to ?? toDate.toISOString().slice(0, 10);
    return this.adminStats.getStatsOverTime(fromStr, toStr);
  }

  @Get('habit-templates')
  @UseGuards(AdminGuard)
  async listTemplates() {
    return this.adminData.listTemplates();
  }

  @Post('habit-templates')
  @UseGuards(AdminGuard)
  async createTemplate(@Body() body: Partial<HabitTemplateDto>) {
    return this.adminData.createTemplate(body);
  }

  @Patch('habit-templates/:id')
  @UseGuards(AdminGuard)
  async updateTemplate(@Param('id') id: string, @Body() body: Partial<HabitTemplateDto>) {
    const t = await this.adminData.updateTemplate(id, body);
    if (!t) return { statusCode: 404, message: 'Not found' };
    return t;
  }

  @Delete('habit-templates/:id')
  @UseGuards(AdminGuard)
  async deleteTemplate(@Param('id') id: string) {
    const ok = await this.adminData.deleteTemplate(id);
    if (!ok) return { statusCode: 404, message: 'Not found' };
    return { ok: true };
  }

  @Get('notices')
  @UseGuards(AdminGuard)
  async listNotices() {
    return this.adminData.listNotices();
  }

  @Post('notices')
  @UseGuards(AdminGuard)
  async createNotice(@Body() body: { title: string; body: string; publishedAt?: string }) {
    return this.adminData.createNotice(body);
  }

  @Patch('notices/:id')
  @UseGuards(AdminGuard)
  async updateNotice(@Param('id') id: string, @Body() body: Partial<NoticeDto>) {
    const n = await this.adminData.updateNotice(id, body);
    if (!n) return { statusCode: 404, message: 'Not found' };
    return n;
  }

  @Delete('notices/:id')
  @UseGuards(AdminGuard)
  async deleteNotice(@Param('id') id: string) {
    const ok = await this.adminData.deleteNotice(id);
    if (!ok) return { statusCode: 404, message: 'Not found' };
    return { ok: true };
  }

  @Get('system-config')
  @UseGuards(AdminGuard)
  async getConfig() {
    return this.adminData.getAllConfig();
  }

  @Patch('system-config')
  @UseGuards(AdminGuard)
  async patchConfig(@Body() body: Record<string, string>) {
    await this.adminData.patchConfig(body);
    return this.adminData.getAllConfig();
  }

  @Get('inquiries')
  @UseGuards(AdminGuard)
  async listInquiries(): Promise<InquiryAdminDto[]> {
    return this.adminData.listInquiries();
  }

  @Patch('inquiries/:id')
  @UseGuards(AdminGuard)
  async updateInquiryReply(
    @Param('id') id: string,
    @Body() body: { adminReply?: string; status?: string },
  ) {
    const r = await this.adminData.updateInquiryReply(id, body);
    if (!r) return { statusCode: 404, message: 'Not found' };
    return r;
  }
}
