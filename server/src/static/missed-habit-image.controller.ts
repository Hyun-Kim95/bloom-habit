import { Controller, Get, Res } from '@nestjs/common';
import type { Response } from 'express';

// Placeholder 이미지: 1x1 PNG (FCM은 imageUrl만 있으면 BigPicture 스타일로 처리됩니다)
// 필요 시 나중에 실제 이미지로 바꿔도 됩니다.
const MISSED_HABIT_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+Xo1kAAAAASUVORK5CYII=';

@Controller('static')
export class MissedHabitImageController {
  @Get('missed_habit.png')
  getMissedHabitImage(@Res() res: Response) {
    res.setHeader('Content-Type', 'image/png');
    res.send(Buffer.from(MISSED_HABIT_PNG_BASE64, 'base64'));
  }
}

