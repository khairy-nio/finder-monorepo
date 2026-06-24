const express = require('express');
const Router  = express.Router();
const adminController  = require('../Controllers/admin.controller');
const reportController = require('../Controllers/report.controller');
const { requireJWT, requireAdmin } = require('../Middlewares/jwt.middleware');
const { verificationResponseValidator } = require('../validators/verification.validator');
const { updateReportStatusValidator } = require('../validators/report.validator');
const { rejectRedemptionValidator } = require('../validators/redemption.validator');
const validate = require('../Middlewares/validation');

// All admin routes require a valid JWT + admin role
Router.use(requireJWT);
Router.use(requireAdmin);

// ─── Dashboard ────────────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/stats
 * @desc    Dashboard overview stats
 */
Router.get('/stats', adminController.getAdminStats);

/**
 * @route   GET /api/v1/admin/notifications
 * @desc    Pending verifications + reports + cash redemptions as notifications
 */
Router.get('/notifications', adminController.getNotifications);

// ─── Users ────────────────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/users
 * @query   ?limit=50&offset=0
 */
Router.get('/users', adminController.getAllUsers);

/**
 * @route   GET /api/v1/admin/users/:userId
 */
Router.get('/users/:userId', adminController.getUserById);

/**
 * @route   PUT /api/v1/admin/users/:userId
 */
Router.put('/users/:userId', adminController.updateUser);

/**
 * @route   DELETE /api/v1/admin/users/:userId
 */
Router.delete('/users/:userId', adminController.deleteUser);

/**
 * @route   PATCH /api/v1/admin/users/:userId/status
 * @body    { status: 'active'|'suspended'|'banned', reason?: string }
 */
Router.patch('/users/:userId/status', adminController.updateUserStatus);

/**
 * @route   POST /api/v1/admin/users/:userId/points/adjust
 * @desc    Manually add or subtract recovery points
 * @body    { points: number }
 */
Router.post('/users/:userId/points/adjust', adminController.adjustUserPoints);

// ─── Posts ────────────────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/posts
 * @query   ?limit=100&offset=0&type=lost|found&status=active|closed&moderation_status=all
 */
Router.get('/posts', adminController.getAllPosts);

/**
 * @route   PUT /api/v1/admin/posts/:postId
 */
Router.put('/posts/:postId', adminController.updatePost);

/**
 * @route   DELETE /api/v1/admin/posts/:postId
 */
Router.delete('/posts/:postId', adminController.deletePost);

/**
 * @route   PATCH /api/v1/admin/posts/:postId/moderation
 * @body    { moderation_status: 'visible'|'hidden'|'removed' }
 */
Router.patch('/posts/:postId/moderation', adminController.updatePostModeration);

// ─── Identity Verifications ───────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/verifications/pending
 */
Router.get('/verifications/pending', adminController.getPendingVerifications);

/**
 * @route   GET /api/v1/admin/verifications
 * @query   ?status=all|pending|approved|rejected
 */
Router.get('/verifications', adminController.getVerifications);

/**
 * @route   POST /api/v1/admin/verifications/:userId/approve
 * @body    { notes?: string }
 */
Router.post('/verifications/:userId/approve',
    verificationResponseValidator, validate,
    adminController.approveVerification);

/**
 * @route   POST /api/v1/admin/verifications/:userId/reject
 * @body    { notes: string }
 */
Router.post('/verifications/:userId/reject',
    verificationResponseValidator, validate,
    adminController.rejectVerification);

// ─── Reports ──────────────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/reports
 * @query   ?limit=100&offset=0&status=pending|resolved
 */
Router.get('/reports', adminController.getAllReports);

/**
 * @route   PUT /api/v1/admin/reports/:id/status
 */
Router.put('/reports/:id/status', updateReportStatusValidator, validate, reportController.updateReportStatus);

// ─── Chat Audit ───────────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/chats/:chatId/messages
 */
Router.get('/chats/:chatId/messages', adminController.getChatMessages);

// ─── Wallet Cash Redemptions ──────────────────────────────────────────────────

/**
 * @route   GET /api/v1/admin/redemptions
 * @desc    List all wallet cash redemption requests
 * @query   ?status=pending|approved|paid|rejected|cancelled|all&limit=50&offset=0
 */
Router.get('/redemptions', adminController.getRedemptions);

/**
 * @route   GET /api/v1/admin/redemptions/:redemptionId
 * @desc    Get details of a single redemption request (includes full wallet number)
 */
Router.get('/redemptions/:redemptionId', adminController.getRedemptionById);

/**
 * @route   POST /api/v1/admin/redemptions/:redemptionId/approve
 * @desc    Approve a pending redemption (admin confirms intent to process payout)
 */
Router.post('/redemptions/:redemptionId/approve', adminController.approveRedemption);

/**
 * @route   POST /api/v1/admin/redemptions/:redemptionId/paid
 * @desc    Mark an approved redemption as paid after the actual wallet transfer is done
 */
Router.post('/redemptions/:redemptionId/paid', adminController.markRedemptionPaid);

/**
 * @route   POST /api/v1/admin/redemptions/:redemptionId/reject
 * @desc    Reject a redemption and automatically refund points to the user
 * @body    { reason: string } (required)
 */
Router.post('/redemptions/:redemptionId/reject',
    rejectRedemptionValidator, validate,
    adminController.rejectRedemption);

/**
 * @route   POST /api/v1/admin/redemptions/:redemptionId/cancel
 * @desc    Cancel a pending redemption and refund points
 */
Router.post('/redemptions/:redemptionId/cancel', adminController.cancelRedemption);

module.exports = Router;
