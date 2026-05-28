const  sequelize  = require('../db/Sequelize');

(async () => {
  try {
    await sequelize.authenticate();
    console.log('Connected to Supabase PostgreSQL');
  } catch (err) {
    console.error('DB connection failed:', err);
  }
})();
