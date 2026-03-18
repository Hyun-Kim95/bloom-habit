import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SystemConfig } from '../entities';
import { ConfigSeedService } from './config-seed.service';
import { ConfigService } from './config.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([SystemConfig])],
  providers: [ConfigService, ConfigSeedService],
  exports: [ConfigService],
})
export class ConfigModule {}
