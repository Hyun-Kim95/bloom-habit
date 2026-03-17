import { Repository } from 'typeorm';
import { User } from '../entities';
export declare class AuthService {
    private readonly userRepo;
    constructor(userRepo: Repository<User>);
    loginGoogle(body: {
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
    loginApple(body: {
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
    private ensureUser;
    logout(_userId: string): Promise<void>;
    getAppUsers(): Promise<{
        id: string;
        email: string | null;
        displayName: string | null;
    }[]>;
}
