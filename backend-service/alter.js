require('dotenv').config();
const sequelize = require('./db/Sequelize');
async function run() {
  try {
    await sequelize.query("ALTER TYPE enum_notifications_type ADD VALUE IF NOT EXISTS 'new_message';");
    await sequelize.query("ALTER TYPE enum_notifications_type ADD VALUE IF NOT EXISTS 'contact_rejected';");
    console.log('Enum updated successfully');
  } catch (e) {
    console.error(e.message);
  } finally {
    process.exit();
  }
}
run();
