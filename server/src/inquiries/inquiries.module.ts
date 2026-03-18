import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtGuard } from '../auth/jwt.guard';
import { Inquiry } from '../entities';
import { InquiriesController } from './inquiries.controller';
import { InquiriesService } from './inquiries.service';

@Module({
  imports: [TypeOrmModule.forFeature([Inquiry])],
  controllers: [InquiriesController],
  providers: [InquiriesService, JwtGuard],
  exports: [InquiriesService],
})
export class InquiriesModule {}
