import { OnModuleInit } from '@nestjs/common';
import { Repository } from 'typeorm';
import { AdminUser } from '../entities';
export declare class AdminAuthService implements OnModuleInit {
    private readonly adminUserRepo;
    constructor(adminUserRepo: Repository<AdminUser>);
    onModuleInit(): Promise<void>;
    login(email: string, password: string): Promise<{
        accessToken: string;
    }>;
    verifyAdminToken(token: string): {
        sub: string;
    };
}
