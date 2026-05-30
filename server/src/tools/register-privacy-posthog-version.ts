import 'dotenv/config';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { LegalDocument } from '../entities';
import { DEFAULT_PRIVACY_CONTENT } from '../legal/default-legal-content';
import { DEFAULT_PRIVACY_CONTENT_EN } from '../legal/default-legal-content-en';

const EFFECTIVE_FROM = '2026-05-31';

async function run() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is missing (server/.env)');
  }

  const ds = new DataSource({
    type: 'postgres',
    url: databaseUrl,
    entities: [LegalDocument],
  });

  await ds.initialize();
  const repo = ds.getRepository(LegalDocument);

  try {
    const maxRow = await repo
      .createQueryBuilder('d')
      .select('MAX(d.version)', 'v')
      .where('d.type = :type', { type: 'privacy' })
      .getRawOne<{ v: string | null }>();
    const nextVersion = (maxRow?.v != null ? parseInt(String(maxRow.v), 10) : 0) + 1;
    const effectiveFrom = new Date(`${EFFECTIVE_FROM}T00:00:00.000Z`);

    const koDoc = repo.create({
      id: `legal-${uuidv4()}`,
      type: 'privacy',
      locale: 'ko',
      version: nextVersion,
      title: '',
      content: DEFAULT_PRIVACY_CONTENT,
      effectiveFrom,
    });
    const enDoc = repo.create({
      id: `legal-${uuidv4()}`,
      type: 'privacy',
      locale: 'en',
      version: nextVersion,
      title: '',
      content: DEFAULT_PRIVACY_CONTENT_EN,
      effectiveFrom,
    });

    await repo.save([koDoc, enDoc]);

    console.log(
      `Registered privacy policy v${nextVersion} (ko+en), effectiveFrom=${EFFECTIVE_FROM}`,
    );
    console.log(`  ko id: ${koDoc.id}`);
    console.log(`  en id: ${enDoc.id}`);
  } finally {
    await ds.destroy();
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
