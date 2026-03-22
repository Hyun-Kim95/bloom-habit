import { Module } from '@nestjs/common';
import { InactiveUserPurgeScheduler } from './inactive-user-purge.scheduler';

@Module({
  providers: [InactiveUserPurgeScheduler],
  exports: [InactiveUserPurgeScheduler],
})
export class MaintenanceModule {}
