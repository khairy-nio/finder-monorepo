require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const sequelize = require('../db/Sequelize');
const { User, Post } = require('../models');

// To seed with your REAL Firebase UID so verfyFirebaseToken resolves your account,
// add this to backend-service/.env:
//   DEV_FIREBASE_UID=<your real Firebase UID from Firebase Console>
//   DEV_USER_EMAIL=yourname@example.com
const DEV_FIREBASE_UID = process.env.DEV_FIREBASE_UID || 'dev-user-placeholder';
const DEV_USER_EMAIL   = process.env.DEV_USER_EMAIL   || 'dev@finder.app';

async function seed() {
  try {
    await sequelize.authenticate();
    console.log('Syncing database schema...');
    // alter:true adds missing columns to existing tables without destroying data.
    // NEVER use force:true here — it drops all tables and deletes everything.
    await sequelize.sync({ alter: true });

    console.log('Seeding local mock users...');

    const [admin] = await User.findOrCreate({
      where: { email: 'admin@admin.com' },
      defaults: {
        id: 'admin-uuid-0000',
        name: 'MOCK ADMIN',
        firebase_uid: 'admin',
        role: 'admin',
        status: 'active',
        verified: true,
        verification_status: 'approved'
      }
    });

    // DEV user: uses your real Firebase UID so you can actually log in via the mobile app.
    const [devUser] = await User.findOrCreate({
      where: { firebase_uid: DEV_FIREBASE_UID },
      defaults: {
        name: 'Dev User',
        email: DEV_USER_EMAIL,
        role: 'user',
        status: 'active',
        verified: true,
        verification_status: 'approved',
        phone_number: '+10000000000',
        country: 'Egypt',
        city: 'Cairo'
      }
    });

    const [user1] = await User.findOrCreate({
      where: { email: 'ahmedbod50@gmail.com' },
      defaults: {
        id: 'user-uuid-0001',
        name: 'Ahmed Bod',
        firebase_uid: 'seed-mock-user1',
        role: 'user',
        status: 'active',
        verified: true,
        verification_status: 'approved',
        phone_number: '+201234567890',
        country: 'Egypt',
        city: 'Cairo'
      }
    });

    const [user2] = await User.findOrCreate({
      where: { email: 'sarah@example.com' },
      defaults: {
        id: 'user-uuid-0002',
        name: 'Sarah Smith',
        firebase_uid: 'seed-mock-user2',
        role: 'user',
        status: 'active',
        verified: false,
        verification_status: 'pending',
        phone_number: '+15550199',
        country: 'USA',
        city: 'New York'
      }
    });

    console.log('Seeding mock posts...');

    await Post.findOrCreate({
      where: { id: 'post-uuid-0001' },
      defaults: {
        user_id: user1.id,
        title: 'Lost iPhone 14 Pro',
        post_type: 'lost',
        category: 'Electronics',
        description: 'Lost my dark purple iPhone 14 Pro near the central mall.',
        country: 'Egypt',
        city: 'Cairo',
        image_url: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5',
        status: 'active'
      }
    });

    await Post.findOrCreate({
      where: { id: 'post-uuid-0002' },
      defaults: {
        user_id: user2.id,
        title: 'Found Keys in Park',
        post_type: 'found',
        category: 'Personal Items',
        description: 'Found a set of keys with a blue keychain on the bench near the lake.',
        country: 'USA',
        city: 'New York',
        image_url: 'https://images.unsplash.com/photo-1582139329536-e7284fece509',
        status: 'active'
      }
    });

    console.log('');
    console.log('✅ Local dev database seeded successfully!');
    console.log('');
    if (DEV_FIREBASE_UID === 'dev-user-placeholder') {
      console.log('⚠️  WARNING: DEV_FIREBASE_UID is not set in .env');
      console.log('   Mobile app Firebase tokens will NOT match any seeded user.');
      console.log('   Add to backend-service/.env:');
      console.log('     DEV_FIREBASE_UID=<your Firebase UID>');
      console.log('     DEV_USER_EMAIL=your@email.com');
      console.log('   Then call POST /api/v1/user/login with your Firebase token to register.');
    } else {
      console.log(`   Dev user seeded with firebase_uid: ${DEV_FIREBASE_UID}`);
    }
  } catch (err) {
    console.error('❌ Error during local seed:', err);
  } finally {
    await sequelize.close();
    process.exit();
  }
}

seed();
