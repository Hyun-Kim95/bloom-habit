export declare function sign(payload: object, expiresInSeconds: number, secret?: string): string;
export declare function verify(token: string, secret?: string): {
    sub: string;
    role?: string;
};
