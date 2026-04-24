const { Client } = require('pg');

async function migrate() {
  const client = new Client({
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
    database: process.env.POSTGRES_DB || 'shortlinks',
    user: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD,
  });

  await client.connect();
  await client.query(`
    CREATE TABLE IF NOT EXISTS short_links (
      id SERIAL PRIMARY KEY,
      code VARCHAR(32) NOT NULL UNIQUE,
      original_url TEXT NOT NULL,
      clicks INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      last_clicked_at TIMESTAMP
    );
  `);
  await client.query('CREATE INDEX IF NOT EXISTS idx_short_links_created_at ON short_links (created_at DESC);');
  await client.end();

  console.log(JSON.stringify({ level: 'info', message: 'Migration complete: short_links table ready' }));
}

migrate().catch((err) => {
  console.error(JSON.stringify({ level: 'error', message: 'Migration failed', error: err.message }));
  process.exit(1);
});
