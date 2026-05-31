'use strict';
const express = require('express');
const Router = express.Router();
const response = require('../utils/response.util');

// ─── AUTH ─────────────────────────────────────────────────────────────────────
// Public + JWT-protected. Used by the admin dashboard.
// POST /api/v1/auth/login    — issue JWT
// GET  /api/v1/auth/me       — validate JWT and return admin profile
const authRoute = require('./auth.route');
Router.use('/auth', authRoute);

// ─── ADMIN (JWT only) ────────────────────────────────────────────────────────
// Every route here requires requireJWT + requireAdmin.
// The mobile app NEVER calls these. Zero Firebase middleware inside.
//
// /api/v1/admin/stats
// /api/v1/admin/users[/:userId]
// /api/v1/admin/posts[/:postId]
// /api/v1/admin/reports[/:id/status]
// /api/v1/admin/verifications[/:userId/approve|reject]
// /api/v1/admin/chats/:chatId/messages
const adminRoute = require('./admin.route');
Router.use('/admin', adminRoute);

// ─── MOBILE (Firebase only) ───────────────────────────────────────────────────
// All routes below are consumed exclusively by the mobile app.
// They are protected by verfyFirebaseToken. The admin dashboard
// NEVER calls these paths directly.

// User profile, KYC, rewards
const userRoute = require('./user.route');
Router.use('/user', userRoute);

// Lost & found posts (public feed + authenticated CRUD)
const PostRoute = require('./post.route');
Router.use('/post', PostRoute);

// AI-powered item matching
const MatchingRoute = require('./matching.route');
Router.use('/match', MatchingRoute);

// Contact requests between users
const ContactReqRoute = require('./contactReq.route');
Router.use('/contact-request', ContactReqRoute);

// Real-time chat
const ChatRoute = require('./chat.route');
Router.use('/chat', ChatRoute);

// Mobile report submission (admin management is under /admin/reports)
const ReportRoute = require('./report.route');
Router.use('/report', ReportRoute);

// Push / in-app notifications
const NotificationRoute = require('./notification.route');
Router.use('/notification', NotificationRoute);

// ─── SYSTEM ───────────────────────────────────────────────────────────────────
Router.get('/status', (_req, res) =>
    response.Success(res, 'API working correctly', { status: 'ok' }, 200)
);
Router.get('/health', (_req, res) =>
    response.Success(res, 'Service healthy', { status: 'ok' }, 200)
);

module.exports = Router;
