'use strict';
const { Sequelize } = require('sequelize');
const path = require('path');

// Load .env from the backend-service root, regardless of where this file is imported from.
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

let sequelize;

console.log('📦 Database Initialization...');

const hasPostgres = !!(process.env.DB_HOST || process.env.DATABASE_URL);

if (hasPostgres) {
  console.log('   - Strategy: PostgreSQL (Supabase)');
  const pg = require('pg');

  // Use individual DB_* vars to avoid URL-parsing issues when the password
  // contains special characters like @.
  const host     = process.env.DB_HOST;
  const port     = Number(process.env.DB_PORT || 6543);
  const database = process.env.DB_NAME || 'postgres';
  const username = process.env.DB_USER;
  const password = process.env.DB_PASS;

  if (!host || !username || !password) {
    console.error('   ❌ Missing DB_HOST / DB_USER / DB_PASS in .env');
    process.exit(1);
  }

  console.log(`   - Host: ${host}:${port}`);
  console.log(`   - User: ${username}`);

  sequelize = new Sequelize(database, username, password, {
    host,
    port,
    dialect:       'postgres',
    dialectModule: pg,
    logging:       process.env.SEQUELIZE_LOGGING === 'true' ? console.log : false,
    pool: {
      // Supabase Session Pooler limits — keep pool small
      max:     Number(process.env.DB_POOL_MAX     || 5),
      min:     Number(process.env.DB_POOL_MIN     || 0),
      acquire: Number(process.env.DB_POOL_ACQUIRE || 30000),
      idle:    Number(process.env.DB_POOL_IDLE    || 10000),
    },
    dialectOptions: {
      ssl: {
        require:            true,
        rejectUnauthorized: false,
      },
      // ⚠️ Required for Supabase Session Pooler (PgBouncer):
      // Named prepared statements are NOT supported in session pooling mode.
      prepare: false,
    },
  });

} else {
  // SQLite fallback for local development without a Supabase DB.
  // Uses ONE deterministic absolute path to avoid multiple SQLite files
  // spawning when scripts run from different directories.
  const dbPath = path.resolve(__dirname, '../lost_and_found.sqlite');
  console.log('   - Strategy: SQLite fallback (DB_HOST not set)');
  console.log(`   - Path: ${dbPath}`);

  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage:  dbPath,
    logging:  false,
  });
}

module.exports = sequelize;
