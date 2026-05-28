require('dotenv').config();
const fs = require('fs');
const path = require('path');
const sequelize = require('../db/Sequelize');
const {
  User,
  Post,
  Chat,
  Message,
  Notification,
  Report
} = require('../models');

const dataDir = path.join(__dirname, 'seed-data');

const shouldTruncate = process.env.SEED_TRUNCATE === 'true';

const loadJson = (name) => {
  const filePath = path.join(dataDir, `${name}.json`);
  if (!fs.existsSync(filePath)) {
    return [];
  }

  const raw = fs.readFileSync(filePath, 'utf8');
  if (!raw.trim()) {
    return [];
  }

  return JSON.parse(raw);
};

const ensureIds = (records, label) => {
  const missing = records.filter((record) => !record.id);
  if (missing.length > 0) {
    throw new Error(`${label} records must include id for relational seeding.`);
  }
};

const normalizeUsers = (users) =>
  users.map((user, index) => ({
    ...user,
    firebase_uid: user.firebase_uid || `seed-user-${user.id || index + 1}`,
    verified: user.verified ?? true,
    verification_status:
      user.verification_status || (user.verified ? 'approved' : 'not_submitted')
  }));

const seed = async () => {
  const users = normalizeUsers(loadJson('users'));
  const posts = loadJson('posts');
  const chats = loadJson('chats');
  const messages = loadJson('messages');
  const notifications = loadJson('notifications');
  const reports = loadJson('reports');

  ensureIds(users, 'User');
  ensureIds(posts, 'Post');
  ensureIds(chats, 'Chat');
  ensureIds(messages, 'Message');
  ensureIds(notifications, 'Notification');
  ensureIds(reports, 'Report');

  await sequelize.authenticate();

  await sequelize.transaction(async (transaction) => {
    if (shouldTruncate) {
      await Message.destroy({ where: {}, truncate: true, cascade: true, transaction });
      await Notification.destroy({ where: {}, truncate: true, cascade: true, transaction });
      await Report.destroy({ where: {}, truncate: true, cascade: true, transaction });
      await Chat.destroy({ where: {}, truncate: true, cascade: true, transaction });
      await Post.destroy({ where: {}, truncate: true, cascade: true, transaction });
      await User.destroy({ where: {}, truncate: true, cascade: true, transaction });
    }

    if (users.length) {
      await User.bulkCreate(users, { transaction });
    }
    if (posts.length) {
      await Post.bulkCreate(posts, { transaction });
    }
    if (chats.length) {
      await Chat.bulkCreate(chats, { transaction });
    }
    if (messages.length) {
      await Message.bulkCreate(messages, { transaction });
    }
    if (notifications.length) {
      await Notification.bulkCreate(notifications, { transaction });
    }
    if (reports.length) {
      await Report.bulkCreate(reports, { transaction });
    }
  });

  await sequelize.close();
  console.log('Seed completed successfully.');
};

seed().catch(async (error) => {
  console.error('Seed failed:', error);
  try {
    await sequelize.close();
  } catch (closeError) {
    console.error('Failed to close DB connection:', closeError);
  }
  process.exit(1);
});
