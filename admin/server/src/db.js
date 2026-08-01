const { Pool } = require('pg');
require('dotenv').config();

// A single shared connection pool for the whole server.
const pool = new Pool({
  connectionString:
    process.env.DATABASE_URL || 'postgres://arete:arete@localhost:5432/arete',
});

pool.on('error', (err) => {
  // eslint-disable-next-line no-console
  console.error('Unexpected PostgreSQL error', err);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
