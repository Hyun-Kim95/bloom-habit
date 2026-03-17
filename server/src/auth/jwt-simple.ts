import * as crypto from 'crypto';

const defaultSecret = process.env.JWT_SECRET ?? 'bloom-habit-dev-secret';

function signWithSecret(
  payload: object,
  expiresInSeconds: number,
  secret: string,
): string {
  const header = { alg: 'HS256', typ: 'JWT' };
  const exp = Math.floor(Date.now() / 1000) + expiresInSeconds;
  const payloadWithExp = { ...payload, exp };
  const b64 = (obj: object) =>
    Buffer.from(JSON.stringify(obj)).toString('base64url');
  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${b64(header)}.${b64(payloadWithExp)}`)
    .digest('base64url');
  return `${b64(header)}.${b64(payloadWithExp)}.${signature}`;
}

export function sign(
  payload: object,
  expiresInSeconds: number,
  secret?: string,
): string {
  return signWithSecret(payload, expiresInSeconds, secret ?? defaultSecret);
}

function verifyWithSecret(
  token: string,
  secret: string,
): { sub: string; role?: string } {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid token');
  const expectedSig = crypto
    .createHmac('sha256', secret)
    .update(`${parts[0]}.${parts[1]}`)
    .digest('base64url');
  if (parts[2] !== expectedSig) throw new Error('Invalid signature');
  const payload = JSON.parse(
    Buffer.from(parts[1], 'base64url').toString('utf8'),
  ) as { sub: string; exp: number; role?: string };
  if (payload.exp && payload.exp < Date.now() / 1000)
    throw new Error('Token expired');
  return { sub: payload.sub, role: payload.role };
}

export function verify(token: string, secret?: string): { sub: string; role?: string } {
  return verifyWithSecret(token, secret ?? defaultSecret);
}
