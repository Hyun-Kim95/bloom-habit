import { DEFAULT_PRIVACY_CONTENT } from '../legal/default-legal-content';
import { DEFAULT_PRIVACY_CONTENT_EN } from '../legal/default-legal-content-en';

const EFFECTIVE_FROM = '2026-05-31';

async function main() {
  const apiBase =
    process.env.API_BASE_URL?.trim() ||
    process.env.PRODUCTION_API_BASE?.trim() ||
    'https://bloom-habit-production.up.railway.app';
  const email = process.env.ADMIN_EMAIL?.trim() || 'admin@bloom.local';
  const password = process.env.ADMIN_PASSWORD?.trim() || 'admin123';

  const loginRes = await fetch(`${apiBase}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!loginRes.ok) {
    throw new Error(`Admin login failed: ${loginRes.status} ${await loginRes.text()}`);
  }
  const { accessToken } = (await loginRes.json()) as { accessToken: string };

  const createRes = await fetch(`${apiBase}/admin/legal-documents`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      type: 'privacy',
      effectiveFrom: EFFECTIVE_FROM,
      titleKo: '',
      contentKo: DEFAULT_PRIVACY_CONTENT,
      titleEn: '',
      contentEn: DEFAULT_PRIVACY_CONTENT_EN,
    }),
  });
  if (!createRes.ok) {
    throw new Error(`Create legal document failed: ${createRes.status} ${await createRes.text()}`);
  }
  const created = (await createRes.json()) as { version: number; id: string };
  console.log(
    `Production privacy v${created.version} registered via ${apiBase} (effectiveFrom=${EFFECTIVE_FROM})`,
  );
  console.log(`  ko document id: ${created.id}`);

  const verifyRes = await fetch(`${apiBase}/legal/privacy?locale=ko`);
  const verify = (await verifyRes.json()) as { version: number; content: string };
  const hasPosthog = verify.content.includes('PostHog');
  console.log(`  verify latest ko v${verify.version}, PostHog mentioned: ${hasPosthog}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
