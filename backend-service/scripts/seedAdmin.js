const User = require('../models/User.model');
const sequelize = require('../db/Sequelize');

async function seedAdmin() {
    try {
        await sequelize.authenticate();
        // Just directly seed an admin override account if you have Firebase matching creds
        const [admin, created] = await User.findOrCreate({
            where: { email: 'admin@admin.com' },
            defaults: {
                name: 'Dashboard Admin',
                firebase_uid: 'PLACEHOLDER_ADMIN_UID_REPLACE_ME_LATER', // You will need to replace this if using existing Firebase user
                role: 'admin',
                status: 'active',
                verification_status: 'approved',
                verified: true
            }
        });
        
        if (!created) {
           await admin.update({ role: 'admin' });
        }
        
        console.log('✅ Admin credentials populated in database:', admin.email);
    } catch (err) {
        console.error('❌ Error seeding admin:', err);
    } finally {
        process.exit();
    }
}
seedAdmin();

