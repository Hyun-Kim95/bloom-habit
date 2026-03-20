import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Notice } from '../entities';
import { PublicNoticesController } from './public-notices.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Notice])],
  controllers: [PublicNoticesController],
})
export class PublicNoticesModule {}
