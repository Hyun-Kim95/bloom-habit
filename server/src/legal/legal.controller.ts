import { Controller, Get, Query } from '@nestjs/common';
import { LegalService, LegalDocumentPublicDto } from './legal.service';

@Controller('legal')
export class LegalController {
  constructor(private readonly legal: LegalService) {}

  @Get('terms')
  async getTerms(
    @Query('locale') locale?: string,
  ): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const loc = locale === 'en' ? 'en' : 'ko';
    const doc = await this.legal.getLatest('terms', loc);
    if (!doc) return { title: '', content: '' };
    return doc;
  }

  @Get('privacy')
  async getPrivacy(
    @Query('locale') locale?: string,
  ): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const loc = locale === 'en' ? 'en' : 'ko';
    const doc = await this.legal.getLatest('privacy', loc);
    if (!doc) return { title: '', content: '' };
    return doc;
  }
}
