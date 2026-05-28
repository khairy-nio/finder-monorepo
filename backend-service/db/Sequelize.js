const { Sequelize } = require('sequelize');

let sequelize;

if (process.env.DATABASE_URL) {
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
  console.log('⚠️  process.env.DATABASE_URL is not set.');
  console.log('🔌 Falling back to local SQLite database: Backend/lost_and_found.sqlite');
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: './lost_and_found.sqlite',
    logging: false
  });
}

module.exports = sequelize;

