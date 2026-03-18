import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtGuard } from '../auth/jwt.guard';
import { InquiriesService } from './inquiries.service';

type ReqWithUser = Request & { userId: string };

@Controller('inquiries')
@UseGuards(JwtGuard)
export class InquiriesController {
  constructor(private readonly inquiries: InquiriesService) {}

  @Post()
  async create(
    @Req() req: ReqWithUser,
    @Body() body: { subject: string; body: string },
  ) {
    return this.inquiries.create(
      req.userId,
      body.subject?.trim() ?? '',
      body.body?.trim() ?? '',
    );
  }

  @Get()
  async list(@Req() req: ReqWithUser) {
    return this.inquiries.listByUser(req.userId);
  }
}
