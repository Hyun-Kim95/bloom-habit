import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AvatarImageController } from './avatar-image.controller';

import { MissedHabitImageController } from './missed-habit-image.controller';

@Module({
  imports: [AuthModule],
  controllers: [MissedHabitImageController, AvatarImageController],
})
export class StaticAssetsModule {}

