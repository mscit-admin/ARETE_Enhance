// Applies db/schema.sql to the configured database.
const fs = require('fs');
const path = require('path');
const { pool } = require('../src/db');

async function main() {
  const sql = fs.readFileSync(
    path.join(__dirname, '..', 'db', 'schema.sql'),
    'utf8',
  );
  await pool.query(sql);
  // eslint-disable-next-line no-console
  console.log('✅ Schema applied.');
  await pool.end();
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Migration failed:', e.message || e.code || String(e));
  if (e.code) console.error('Error code:', e.code);
  if (e.code === 'ECONNREFUSED') {
    console.error(
      'PostgreSQL is not reachable at the configured host/port. ' +
        'Check DATABASE_URL in .env (default port is 5432).',
    );
  }
  process.exit(1);
});
