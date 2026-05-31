const { Sequelize } = require('sequelize');
const path = require('path');

// Ensure environment variables are loaded FIRST before checking DATABASE_URL.
// We use path.resolve to guarantee we load the .env file from the root backend-service directory,
// regardless of where this script is imported from.

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

let sequelize;

console.log('📦 Database Initialization...');
console.log(`   - Env loaded: ${!!process.env.PORT || !!process.env.DATABASE_URL}`);

if (process.env.DATABASE_URL) {
  console.log('   - Strategy: PostgreSQL (DATABASE_URL provided)');
  const pg = require('pg');
  sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    dialectModule: pg,
    logging: process.env.SEQUELIZE_LOGGING === 'true' ? console.log : false,
    pool: {
      max: Number(process.env.DB_POOL_MAX || 10),
      min: Number(process.env.DB_POOL_MIN || 0),
      acquire: Number(process.env.DB_POOL_ACQUIRE || 30000),
      idle: Number(process.env.DB_POOL_IDLE || 10000)
    },
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false,
      },
    },
  });
} else {
  // Use ONE deterministic, absolute path for the SQLite database fallback.
  // This prevents multiple SQLite databases like "Backend/lost_and_found.sqlite"
  // from silently spawning when scripts are executed from different subdirectories.
  const dbPath = path.resolve(__dirname, '../lost_and_found.sqlite');
  console.log('   - Strategy: SQLite fallback (DATABASE_URL is not set)');
  console.log(`   - Path: ${dbPath}`);

  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: dbPath,
    logging: false
  });
}

module.exports = sequelize;

