import { Controller, Get, Param } from '@nestjs/common';
import { LegalService, LegalDocumentPublicDto } from './legal.service';

@Controller('legal')
export class LegalController {
  constructor(private readonly legal: LegalService) {}

  @Get('terms')
  async getTerms(): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const doc = await this.legal.getLatest('terms');
    if (!doc) return { title: '이용약관', content: '' };
    return doc;
  }

  @Get('privacy')
  async getPrivacy(): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const doc = await this.legal.getLatest('privacy');
    if (!doc) return { title: '개인정보처리방침', content: '' };
    return doc;
  }
}
