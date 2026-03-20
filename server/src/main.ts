import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: true }); // 개발용; 프로덕션에서는 origin 제한
  // 개발 시 요청 로그 (서버에 요청이 오는지 확인용)
  if (process.env.NODE_ENV !== 'production') {
    app.use((req: any, _res: any, next: () => void) => {
      console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
      next();
    });
  }
  const port = Number(process.env.PORT ?? 3000);
  // Listen on all interfaces so Android emulator (10.0.2.2 → host) and LAN devices can connect.
  await app.listen(port, '0.0.0.0');
  console.log(`Server listening on http://0.0.0.0:${port} (localhost:${port})`);
}
bootstrap();
