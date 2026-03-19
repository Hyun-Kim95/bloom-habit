import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LegalDocument } from '../entities';
import { LegalController } from './legal.controller';
import { LegalService } from './legal.service';

@Module({
  imports: [TypeOrmModule.forFeature([LegalDocument])],
  controllers: [LegalController],
  providers: [LegalService],
})
export class LegalModule {}
