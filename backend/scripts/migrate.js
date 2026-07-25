require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function migrate() {
  const migrationsDir = path.join(__dirname, '..', 'database', 'migrations');
  const files = fs.readdirSync(migrationsDir).filter((file) => file.endsWith('.sql')).sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    console.log(`Ejecutando migración: ${file}`);
    await pool.query(sql);
  }

  await pool.end();
  console.log('Migraciones completadas correctamente.');
}

migrate().catch(async (error) => {
  console.error('Error ejecutando migraciones:', error.message);
  await pool.end();
  process.exit(1);
});
