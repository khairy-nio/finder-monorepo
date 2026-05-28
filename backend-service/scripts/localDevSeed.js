const sequelize = require('../db/Sequelize');
const { User, Post } = require('../models');

async function seed() {
  try {
    await sequelize.authenticate();
    console.log('Syncing database...');
    await sequelize.sync({ force: true });

    console.log('Seeding local mock users...');
    
    // Seed Admin
    await User.create({
      id: 'admin-uuid-0000',
      name: 'MOCK ADMIN',
      email: 'admin@admin.com',
      firebase_uid: 'admin',
      role: 'admin',
      status: 'active',
      verified: true,
      verification_status: 'approved'
    });

    // Seed Regular Users
    const user1 = await User.create({
      id: 'user-uuid-0001',
      name: 'Ahmed Bod',
      email: 'ahmedbod50@gmail.com',
      firebase_uid: 'user1',
      role: 'user',
      status: 'active',
      verified: true,
      verification_status: 'approved',
      phone_number: '+201234567890',
      country: 'Egypt',
      city: 'Cairo'
    });

    const user2 = await User.create({
      id: 'user-uuid-0002',
      name: 'Sarah Smith',
      email: 'sarah@example.com',
      firebase_uid: 'user2',
      role: 'user',
      status: 'active',
      verified: false,
      verification_status: 'pending',
      phone_number: '+15550199',
      country: 'USA',
      city: 'New York'
    });

    const user3 = await User.create({
      id: 'user-uuid-0003',
      name: 'Mohamed Aly',
      email: 'mohamed@example.com',
      firebase_uid: 'user3',
      role: 'user',
      status: 'active',
      verified: false,
      verification_status: 'not_submitted',
      phone_number: '+20100999999',
      country: 'Egypt',
      city: 'Alexandria'
    });

    console.log('Seeding mock posts...');
    
    await Post.create({
      id: 'post-uuid-0001',
      user_id: user1.id,
      title: 'Lost iPhone 14 Pro',
      post_type: 'lost',
      category: 'Electronics',
      description: 'Lost my dark purple iPhone 14 Pro near the central mall. It has a black leather case.',
      country: 'Egypt',
      city: 'Cairo',
      image_url: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5',
      status: 'active'
    });

    await Post.create({
      id: 'post-uuid-0002',
      user_id: user2.id,
      title: 'Found Keys in Park',
      post_type: 'found',
      category: 'Personal Items',
      description: 'Found a set of keys with a blue keychain on the bench near the lake.',
      country: 'USA',
      city: 'New York',
      image_url: 'https://images.unsplash.com/photo-1582139329536-e7284fece509',
      status: 'active'
    });

    console.log('✅ Local dev database seeded successfully!');
  } catch (err) {
    console.error('❌ Error during local seed:', err);
  } finally {
    process.exit();
  }
}

seed();
