import { Controller, Get, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { LegalService, LegalDocumentPublicDto } from './legal.service';

@Controller('legal')
export class LegalController {
  constructor(private readonly legal: LegalService) {}

  private resolveLocale(locale?: string): 'ko' | 'en' {
    return locale === 'en' ? 'en' : 'ko';
  }

  private escapeHtml(value: string): string {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  private renderLegalHtml(
    title: string,
    content: string,
    locale: 'ko' | 'en',
  ): string {
    const pageTitle = title.trim().length > 0 ? title : locale === 'en' ? 'Legal document' : '법률 문서';
    const bodyContent = content.trim().length > 0
      ? this.escapeHtml(content)
      : this.escapeHtml(
          locale === 'en'
            ? 'No legal content has been published yet.'
            : '아직 게시된 문서가 없습니다.',
        );
    return `<!doctype html>
<html lang="${locale}">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${this.escapeHtml(pageTitle)} | HabitFable</title>
    <style>
      body { margin: 0; background: #f8fafc; color: #0f172a; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans KR", sans-serif; }
      main { max-width: 900px; margin: 0 auto; padding: 24px 16px 48px; }
      h1 { font-size: 26px; line-height: 1.3; margin: 0 0 16px; }
      pre { margin: 0; padding: 20px; border: 1px solid #d7dde4; border-radius: 12px; white-space: pre-wrap; word-break: break-word; background: #fff; font-size: 14px; line-height: 1.7; }
    </style>
  </head>
  <body>
    <main>
      <h1>${this.escapeHtml(pageTitle)}</h1>
      <pre>${bodyContent}</pre>
    </main>
  </body>
</html>`;
  }

  @Get('terms')
  async getTerms(
    @Query('locale') locale?: string,
  ): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const loc = this.resolveLocale(locale);
    const doc = await this.legal.getLatest('terms', loc);
    if (!doc) return { title: '', content: '' };
    return doc;
  }

  @Get('privacy')
  async getPrivacy(
    @Query('locale') locale?: string,
  ): Promise<LegalDocumentPublicDto | { content: ''; title: string }> {
    const loc = this.resolveLocale(locale);
    const doc = await this.legal.getLatest('privacy', loc);
    if (!doc) return { title: '', content: '' };
    return doc;
  }

  @Get('terms-page')
  async getTermsPage(
    @Query('locale') locale: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const loc = this.resolveLocale(locale);
    const doc = await this.legal.getLatest('terms', loc);
    const html = this.renderLegalHtml(doc?.title ?? '', doc?.content ?? '', loc);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  }

  @Get('privacy-page')
  async getPrivacyPage(
    @Query('locale') locale: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const loc = this.resolveLocale(locale);
    const doc = await this.legal.getLatest('privacy', loc);
    const html = this.renderLegalHtml(doc?.title ?? '', doc?.content ?? '', loc);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  }
}
