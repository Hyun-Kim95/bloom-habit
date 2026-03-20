import 'dotenv/config';
import { DataSource } from 'typeorm';
import { User, Habit, Inquiry, MissedHabitPushLog } from '../entities';

function normalizeEmail(email: string | null): string | null {
  if (!email) return null;
  const v = email.trim().toLowerCase();
  return v === '' ? null : v;
}

async function run() {
  const apply = process.argv.includes('--apply');
  const emailArg = process.argv.find((a) => a.startsWith('--email='));
  const targetEmail = emailArg ? emailArg.slice('--email='.length).trim().toLowerCase() : null;
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is missing');
  }

  const ds = new DataSource({
    type: 'postgres',
    url: databaseUrl,
    entities: [User, Habit, Inquiry, MissedHabitPushLog],
  });

  await ds.initialize();
  const queryRunner = ds.createQueryRunner();
  await queryRunner.connect();

  try {
    const users = await queryRunner.manager.find(User, { order: { createdAt: 'ASC' } });
    const byEmail = new Map<string, User[]>();
    for (const u of users) {
      const e = normalizeEmail(u.email);
      if (!e) continue;
      if (targetEmail && e !== targetEmail) continue;
      if (!byEmail.has(e)) byEmail.set(e, []);
      byEmail.get(e)!.push(u);
    }

    const duplicateGroups = [...byEmail.entries()].filter(([, list]) => list.length > 1);
    if (duplicateGroups.length === 0) {
      console.log('No duplicate users found.');
      return;
    }

    console.log(`Found ${duplicateGroups.length} duplicate email group(s).`);

    if (apply) {
      await queryRunner.startTransaction();
    }

    let mergedCount = 0;
    for (const [email, list] of duplicateGroups) {
      // Keep oldest account as canonical.
      const sorted = [...list].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
      const primary = sorted[0];
      const duplicates = sorted.slice(1);
      console.log(`\n[${email}] keep=${primary.id}, merge=${duplicates.map((d) => d.id).join(', ')}`);

      for (const d of duplicates) {
        if (apply) {
          await queryRunner.manager
            .createQueryBuilder()
            .update(Habit)
            .set({ userId: primary.id })
            .where('userId = :id', { id: d.id })
            .execute();

          await queryRunner.manager
            .createQueryBuilder()
            .update(Inquiry)
            .set({ userId: primary.id })
            .where('userId = :id', { id: d.id })
            .execute();

          // Handle unique(userId, pushDate) collisions by deleting duplicate-side rows first.
          const duplicateLogs = await queryRunner.manager.find(MissedHabitPushLog, {
            where: { userId: d.id },
          });
          for (const log of duplicateLogs) {
            const existing = await queryRunner.manager.findOne(MissedHabitPushLog, {
              where: { userId: primary.id, pushDate: log.pushDate },
            });
            if (existing) {
              await queryRunner.manager.delete(MissedHabitPushLog, { id: log.id });
            } else {
              await queryRunner.manager.update(MissedHabitPushLog, { id: log.id }, { userId: primary.id });
            }
          }

          await queryRunner.manager.delete(User, { id: d.id });
        }
        mergedCount++;
      }
    }

    if (apply) {
      await queryRunner.commitTransaction();
      console.log(`\nMerged ${mergedCount} duplicate account(s).`);
    } else {
      console.log('\nDry-run complete. Re-run with --apply to execute.');
    }
  } catch (e) {
    if (queryRunner.isTransactionActive) {
      await queryRunner.rollbackTransaction();
    }
    throw e;
  } finally {
    await queryRunner.release();
    await ds.destroy();
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});

