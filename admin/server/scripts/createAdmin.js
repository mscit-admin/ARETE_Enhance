// Create or update the admin account WITHOUT touching any other data.
// Usage:  ADMIN_EMAIL=you@club.com ADMIN_PASSWORD=secret npm run create-admin
// (or)    node scripts/createAdmin.js you@club.com secret
const bcrypt = require('bcryptjs');
const { pool } = require('../src/db');
require('dotenv').config();

const email = (process.env.ADMIN_EMAIL || process.argv[2] || '')
  .trim()
  .toLowerCase();
const password = process.env.ADMIN_PASSWORD || process.argv[3];
const name = process.env.ADMIN_NAME || 'Club Admin';

async function main() {
  if (!email || !password) {
    // eslint-disable-next-line no-console
    console.error(
      'Provide ADMIN_EMAIL and ADMIN_PASSWORD (env or two CLI args).',
    );
    process.exit(1);
  }
  const hash = await bcrypt.hash(password, 10);
  await pool.query(
    `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1, $2, $3, 'admin')
     ON CONFLICT (email)
       DO UPDATE SET password_hash = EXCLUDED.password_hash,
                     full_name = EXCLUDED.full_name,
                     role = 'admin'`,
    [email, hash, name],
  );
  // eslint-disable-next-line no-console
  console.log(`✅ Admin ready: ${email}`);
  await pool.end();
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Failed to create admin:', e.message);
  process.exit(1);
});
