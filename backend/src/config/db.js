const { Pool } = require('pg');

let pool;

if (process.env.NODE_ENV === 'test') {
  if (!global.testDbPool) {
    const { newDb, DataType } = require('pg-mem');
    const memoryDb = newDb({ autoCreateForeignKeyIndices: true });
    
    // Registrar uuidv4/gen_random_uuid
    memoryDb.public.registerFunction({
      name: 'gen_random_uuid',
      returns: DataType.uuid,
      implementation: () => require('node:crypto').randomUUID(),
      impure: true
    });

    const adapter = memoryDb.adapters.createPg();
    global.testDbPool = new adapter.Pool();
    global.isTestDbInitialized = false;
  }
  pool = global.testDbPool;
} else {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL
  });
}

async function initializeTestDb() {
  const fs = require('node:fs');
  const path = require('node:path');
  
  const migrationsDir = path.join(__dirname, '..', '..', 'database', 'migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));
  
  for (const file of files) {
    let sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    
    // Eliminar extensiones no soportadas por pg-mem
    sql = sql.replace(/CREATE EXTENSION IF NOT EXISTS pgcrypto;/gi, '');
    
    // Convertir bloques DO $$ BEGIN CREATE TYPE ... END $$; a CREATE TYPE simple
    sql = sql.replace(/DO \$\$ BEGIN/gi, '');
    sql = sql.replace(/EXCEPTION WHEN duplicate_object THEN NULL;\s*END \$\$;/gi, '');
    
    // Reemplazar precisiones decimal/numeric no soportadas por el AST de pg-mem
    sql = sql.replace(/DECIMAL\(\d+,\s*\d+\)/gi, 'DECIMAL');
    sql = sql.replace(/NUMERIC\(\d+,\s*\d+\)/gi, 'NUMERIC');
    
    // Partir la migración por punto y coma para ejecutar línea por línea y poder ignorar errores individuales
    const statements = sql
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);

    for (const stmt of statements) {
      try {
        await pool.query(stmt);
      } catch (err) {
        const msg = err.message.toLowerCase();
        if (
          msg.includes('already exists') ||
          msg.includes('not supported') ||
          err.code === '42710' ||
          err.code === '42P07'
        ) {
          // Ignorar tipo, tabla o índice ya existente, o limitaciones de AST de pg-mem en sentencias redundantes
          continue;
        }
        console.error(`Error al ejecutar sentencia de migración ${file}:`, err.message, '\nSentencia:', stmt);
        throw err;
      }
    }
  }
  global.isTestDbInitialized = true;
}

module.exports = {
  pool,
  query: async (text, params) => {
    if (process.env.NODE_ENV === 'test' && !global.isTestDbInitialized) {
      await initializeTestDb();
    }
    return pool.query(text, params);
  },
  initializeTestDb
};
