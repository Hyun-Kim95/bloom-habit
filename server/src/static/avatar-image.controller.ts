import { Controller, Get, NotFoundException, Param, Res } from '@nestjs/common';
import { createReadStream, existsSync } from 'fs';
import { join } from 'path';
import type { Response } from 'express';

@Controller('static')
export class AvatarImageController {
  @Get('avatars/:fileName')
  getAvatar(@Param('fileName') fileName: string, @Res() res: Response) {
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '');
    if (!safeName) throw new NotFoundException('File not found');
    const filePath = join(process.cwd(), 'uploads', 'avatars', safeName);
    if (!existsSync(filePath)) throw new NotFoundException('File not found');
    if (safeName.endsWith('.png')) {
      res.type('image/png');
    } else if (safeName.endsWith('.webp')) {
      res.type('image/webp');
    } else {
      res.type('image/jpeg');
    }
    return createReadStream(filePath).pipe(res);
  }
}
