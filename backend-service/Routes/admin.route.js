const express = require('express');
const Router = express.Router();
const adminController = require('../Controllers/admin.controller');
const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const isAdmin = require('../Middlewares/isAdmin.middleware');
const { verificationResponseValidator } = require('../validators/verification.validator');
const validate = require('../Middlewares/validation');

// Apply authentication and admin check to ALL routes
Router.use(verfyFirebaseToken);
Router.use(isAdmin);

/**
 * @route   GET /api/v1/admin/stats
 * @desc    Get dashboard overview status
 * @access  Admin only
 */
Router.get('/stats', adminController.getAdminStats);

/**
 * @route   GET /api/v1/admin/users
 * @desc    Get all users with pagination
 * @access  Admin only
 * @query   ?limit=50&offset=0
 */
Router.get('/users', adminController.getAllUsers);

/**
 * @route   GET /api/v1/admin/users/:userId
 * @desc    Get specific user details by ID
 * @access  Admin only
 */
Router.get('/users/:userId', adminController.getUserById);

Router.put('/users/:userId', adminController.updateUser);

/**
 * @route   DELETE /api/v1/admin/users/:userId
 * @desc    Delete any user account (admin privilege)
 * @access  Admin only
 */
Router.delete('/users/:userId', adminController.deleteUser);

/**
 * @route   PUT /api/v1/admin/posts/:postId
 * @desc    Update any post (admin privilege)
 * @access  Admin only
 * @body    Post update data
 */
Router.put('/posts/:postId', adminController.updatePost);

/**
 * @route   DELETE /api/v1/admin/posts/:postId
 * @desc    Delete any post (admin privilege)
 * @access  Admin only
 */
Router.delete('/posts/:postId', adminController.deletePost);

/**
 * @route   GET /api/v1/admin/verifications/pending
 * @desc    Get all pending identity verifications
 * @access  Admin only
 * @query   ?limit=50&offset=0
 */
Router.get('/verifications/pending', adminController.getPendingVerifications);

/**
 * @route   GET /api/v1/admin/verifications
 * @desc    Get all identity verifications with optional status filter
 * @access  Admin only
 * @query   ?limit=50&offset=0&status=all|pending|approved|rejected
 */
Router.get('/verifications', adminController.getVerifications);

/**
 * @route   POST /api/v1/admin/verifications/:userId/approve
 * @desc    Approve user's identity verification
 * @access  Admin only
 * @body    { notes?: string }
 */
Router.post('/verifications/:userId/approve',
    verificationResponseValidator,
    validate,
    adminController.approveVerification);

/**
 * @route   POST /api/v1/admin/verifications/:userId/reject
 * @desc    Reject user's identity verification
 * @access  Admin only
 * @body    { notes: string } (required)
 */
Router.post('/verifications/:userId/reject',
    verificationResponseValidator,
    validate,
    adminController.rejectVerification);

/**
 * @route   PATCH /api/v1/admin/users/:userId/status
 * @desc    Update user account status (active/suspended/banned)
 * @access  Admin only
 * @body    { status: 'active'|'suspended'|'banned' }
 */
Router.patch('/users/:userId/status', adminController.updateUserStatus);

/**
 * @route   PATCH /api/v1/admin/posts/:postId/moderation
 * @desc    Update post moderation status (visible/hidden/removed)
 * @access  Admin only
 * @body    { moderation_status: 'visible'|'hidden'|'removed' }
 */
Router.patch('/posts/:postId/moderation', adminController.updatePostModeration);

/**
 * @route   POST /api/v1/admin/users/:userId/points/adjust
 * @desc    Adjust user's recovery points (admin manual override)
 * @access  Admin only
 * @body    { points: number, reason?: string }
 */
Router.post('/users/:userId/points/adjust', adminController.adjustUserPoints);

/**
 * @route   GET /api/v1/admin/chats/:chatId/messages
 * @desc    Get full chat conversation history for admin audit
 * @access  Admin only
 */
Router.get('/chats/:chatId/messages', adminController.getChatMessages);

module.exports = Router;

