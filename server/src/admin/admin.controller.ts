import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AuthService } from '../auth/auth.service';
import { HabitsService } from '../habits/habits.service';
import { AdminAuthService } from './admin-auth.service';
import { AdminDataService, HabitTemplateDto, NoticeDto } from './admin-data.service';
import { AdminGuard } from './admin.guard';

@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminAuth: AdminAuthService,
    private readonly adminData: AdminDataService,
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
    return this.auth.getAppUsers();
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
}
