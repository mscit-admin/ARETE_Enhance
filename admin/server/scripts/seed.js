// Seeds sample data (admin, trainers, members, memberships, payments, sessions).
// Safe to re-run: it clears the domain tables first.
const bcrypt = require('bcryptjs');
const { pool } = require('../src/db');
require('dotenv').config();

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@arete.fit';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Clear domain data (respect FK order).
    await client.query(`
      TRUNCATE payments, memberships, plan_assignments, coach_sessions,
               workout_sessions, members, trainers, plans, users RESTART IDENTITY CASCADE;
    `);

    const adminHash = await bcrypt.hash(ADMIN_PASSWORD, 10);
    const memberHash = await bcrypt.hash('member123', 10);

    // Admin
    await client.query(
      `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1, $2, 'Club Admin', 'admin')`,
      [ADMIN_EMAIL, adminHash],
    );

    // Trainers
    const trainers = [
      ['sara.k@arete.fit', 'Sara Kessler', 'Strength & Hypertrophy', 4.9, 1],
      ['omar.f@arete.fit', 'Omar Farouk', 'Conditioning', 4.7, 2],
    ];
    const trainerIds = [];
    for (const [email, name, specialty, rating, resp] of trainers) {
      const u = await client.query(
        `INSERT INTO users (email, password_hash, full_name, role)
         VALUES ($1, $2, $3, 'trainer') RETURNING id`,
        [email, memberHash, name],
      );
      const id = u.rows[0].id;
      trainerIds.push(id);
      await client.query(
        `INSERT INTO trainers (user_id, specialty, certifications, rating, avg_response_h)
         VALUES ($1, $2, $3, $4, $5)`,
        [id, specialty, ['NASM-CPT'], rating, resp],
      );
    }

    // Members — spread sign-ups across the last 12 weeks for the growth chart.
    const tiers = ['basic', 'silver', 'gold', 'elite'];
    const tierPrice = { basic: 20, silver: 35, gold: 55, elite: 90 };
    const statuses = ['active', 'active', 'active', 'active', 'frozen', 'expired'];
    const firstNames = ['Yahya', 'Priya', 'Marcus', 'Dana', 'Rana', 'Leo', 'Mona', 'Sami',
      'Aya', 'Nabil', 'Hana', 'Karim', 'Lina', 'Tariq', 'Sara', 'Yousef'];
    const lastNames = ['Gashott', 'Nair', 'Lee', 'Ortiz', 'Hadi', 'Costa', 'Aziz', 'Rahman'];

    let created = 0;
    for (let week = 11; week >= 0; week--) {
      // more sign-ups in recent weeks
      const count = 3 + Math.round((11 - week) / 2);
      for (let i = 0; i < count; i++) {
        const fn = firstNames[created % firstNames.length];
        const ln = lastNames[created % lastNames.length];
        const email = `member${created}@example.com`;
        const tier = tiers[created % tiers.length];
        const status = statuses[created % statuses.length];
        const trainerId = created % 3 === 2 ? null : trainerIds[created % trainerIds.length];

        const u = await client.query(
          `INSERT INTO users (email, password_hash, full_name, role, created_at)
           VALUES ($1, $2, $3, 'member', now() - ($4 || ' days')::interval)
           RETURNING id`,
          [email, memberHash, `${fn} ${ln}`, String(week * 7 + i)],
        );
        const mid = u.rows[0].id;
        await client.query(
          `INSERT INTO members (user_id, goal, experience, height_cm, weight_kg, trainer_id, current_streak_days)
           VALUES ($1, 'build_muscle', 'intermediate', 178, $2, $3, $4)`,
          [mid, 70 + (created % 20), trainerId, created % 30],
        );

        const membershipStatus = status === 'expired' ? 'expired' : (status === 'frozen' ? 'frozen' : 'active');
        const m = await client.query(
          `INSERT INTO memberships (member_id, tier, status, started_on, renews_on, price)
           VALUES ($1, $2, $3, current_date - interval '20 days',
                   current_date + (($4)::int || ' days')::interval, $5)
           RETURNING id`,
          [mid, tier, membershipStatus, (created % 40) - 5, tierPrice[tier]],
        );

        // A paid payment for active/frozen members (drives MRR/revenue).
        if (membershipStatus !== 'expired') {
          await client.query(
            `INSERT INTO payments (member_id, membership_id, amount, method, status, paid_at)
             VALUES ($1, $2, $3, 'card', 'paid', now() - ($4 || ' days')::interval)`,
            [mid, m.rows[0].id, tierPrice[tier], String(created % 25)],
          );
        }

        // A couple of workout sessions, some today.
        const sessionsToAdd = created % 3;
        for (let s = 0; s < sessionsToAdd; s++) {
          await client.query(
            `INSERT INTO workout_sessions (member_id, title, started_at, finished_at, total_volume, pr_count)
             VALUES ($1, 'Push Day', now() - ($2 || ' hours')::interval,
                     now() - ($2 || ' hours')::interval + interval '50 min', $3, $4)`,
            [mid, String(s * 6), 4000 + created * 20, created % 2],
          );
        }
        created++;
      }
    }

    // A few starter plans
    const plans = [
      ['Foundation 3-Day Full Body', 'Full body', 3, 'general_fitness', 'beginner'],
      ['Upper / Lower 4-Day', 'Upper / Lower', 4, 'build_muscle', 'intermediate'],
      ['Push / Pull / Legs 6-Day', 'PPL', 6, 'build_muscle', 'advanced'],
    ];
    for (const [name, split, days, goal, exp] of plans) {
      await client.query(
        `INSERT INTO plans (name, split, days_per_week, goal, experience, created_by)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [name, split, days, goal, exp, trainerIds[0]],
      );
    }

    await client.query('COMMIT');
    // eslint-disable-next-line no-console
    console.log(`✅ Seeded: 1 admin, ${trainers.length} trainers, ${created} members.`);
    console.log(`   Admin login: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Seed failed:', e.message);
  process.exit(1);
});
