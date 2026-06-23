require('dotenv').config({ path: '.env' });
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(process.env.DB_NAME, process.env.DB_USER, process.env.DB_PASS, {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  dialect: 'postgres',
  logging: false,
  dialectOptions: {
    ssl: { require: true, rejectUnauthorized: false }
  }
});

async function verifyAllUsers() {
  try {
    await sequelize.authenticate();
    const [results, metadata] = await sequelize.query(`UPDATE "users" SET "verified" = true WHERE "verified" = false;`);
    console.log(`✅ Successfully verified ${metadata.rowCount || metadata} users!`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error updating users:', err);
    process.exit(1);
  }
}

verifyAllUsers();
