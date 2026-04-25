import 'dotenv/config';
import path from 'node:path';
import { DataSource } from 'typeorm';
import {
  typeOrmConnectionExtras,
  typeOrmEntities,
} from './typeorm-base.config';

/**
 * TypeORM CLI 전용 DataSource (`npm run migration:*`).
 * CLI는 이 파일에 **DataSource 인스턴스 export가 하나만** 있어야 한다.
 * Nest 런타임은 `app.module.ts`의 TypeOrmModule.forRoot 를 사용한다.
 */
export default new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: typeOrmEntities,
  migrations: [path.join(__dirname, '..', 'migrations', '*.{js,ts}')],
  synchronize: false,
  logging: process.env.TYPEORM_LOGGING === 'true',
  extra: typeOrmConnectionExtras,
});
