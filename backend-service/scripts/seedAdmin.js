require('dotenv').config();
const bcrypt = require('bcryptjs');
const User = require('../models/User.model');
const sequelize = require('../db/Sequelize');

const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    || 'admin@finder.app';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin@1234!';
const ADMIN_NAME     = process.env.ADMIN_NAME     || 'Dashboard Admin';

async function seedAdmin() {
    try {
        await sequelize.authenticate();
        await sequelize.sync();

        const password_hash = await bcrypt.hash(ADMIN_PASSWORD, 12);

        const [admin, created] = await User.findOrCreate({
            where: { email: ADMIN_EMAIL },
            defaults: {
                name: ADMIN_NAME,
                firebase_uid: `jwt-admin-${Date.now()}`,
                role: 'admin',
                status: 'active',
                verification_status: 'approved',
                verified: true,
                password_hash,
            },
        });

        if (!created) {
            await admin.update({ role: 'admin', password_hash });
            console.log('✅ Existing admin updated with hashed password:', admin.email);
        } else {
            console.log('✅ Admin created:', admin.email);
        }

        console.log(`\n🔑 Admin credentials:`);
        console.log(`   Email   : ${ADMIN_EMAIL}`);
        console.log(`   Password: ${ADMIN_PASSWORD}`);
        console.log(`\n   Change ADMIN_PASSWORD in .env before deploying to production!\n`);
    } catch (err) {
        console.error('❌ Error seeding admin:', err);
    } finally {
        await sequelize.close();
        process.exit();
    }
}

seedAdmin();
