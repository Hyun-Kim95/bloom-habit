import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtGuard } from '../auth/jwt.guard';
import { Notice, NoticeRead } from '../entities';
import { NoticeSeedService } from './notice-seed.service';
import { PublicNoticesController } from './public-notices.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Notice, NoticeRead])],
  controllers: [PublicNoticesController],
  providers: [NoticeSeedService, JwtGuard],
})
export class PublicNoticesModule {}
