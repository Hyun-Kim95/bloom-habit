import { Module } from '@nestjs/common';

import { MissedHabitImageController } from './missed-habit-image.controller';

@Module({
  controllers: [MissedHabitImageController],
})
export class StaticAssetsModule {}

