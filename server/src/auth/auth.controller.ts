import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('google')
  async google(
    @Body()
    body: {
      idToken: string;
      email?: string;
      displayName?: string;
      /** Google 프로필 사진 URL */
      avatarUrl?: string | null;
    },
  ) {
    return this.auth.loginGoogle(body);
  }

  @Post('apple')
  async apple(
    @Body()
    body: {
      identityToken: string;
      email?: string;
      displayName?: string;
    },
  ) {
    return this.auth.loginApple(body);
  }

  @Post('logout')
  async logout() {
    return { ok: true };
  }
}
