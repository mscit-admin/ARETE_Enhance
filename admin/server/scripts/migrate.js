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
  console.error('Migration failed:', e.message);
  process.exit(1);
});
