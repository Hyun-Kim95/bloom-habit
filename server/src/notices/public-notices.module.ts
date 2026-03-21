import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Notice } from '../entities';
import { NoticeSeedService } from './notice-seed.service';
import { PublicNoticesController } from './public-notices.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Notice])],
  controllers: [PublicNoticesController],
  providers: [NoticeSeedService],
})
export class PublicNoticesModule {}
