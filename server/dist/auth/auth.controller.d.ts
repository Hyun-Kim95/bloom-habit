import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly auth;
    constructor(auth: AuthService);
    google(body: {
        idToken: string;
    }): Promise<{
        accessToken: string;
        refreshToken: string | null;
        user: {
            id: string;
            email: string | null;
            displayName: string | null;
        };
    }>;
    apple(body: {
        identityToken: string;
        email?: string;
        displayName?: string;
    }): Promise<{
        accessToken: string;
        refreshToken: string | null;
        user: {
            id: string;
            email: string | null;
            displayName: string | null;
        };
    }>;
    logout(): Promise<{
        ok: boolean;
    }>;
}
