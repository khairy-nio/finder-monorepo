const response = require('../utils/response.util');
const UserService = require('../services/user.service');
const PostService = require('../services/Post.service');
const RecoveryService = require('../services/recovery.service');


class AdminController {

    /**
     * Get lightweight admin stats for the dashboard overview
     */
    async getAdminStats(req, res) {
        try {
            const User = require('../models/User.model');
            const Post = require('../models/post.model');
            const Report = require('../models/Report.model');
            const UserVerification = require('../models/UserVerification.model');
            const RecoveryRedemption = require('../models/RecoveryRedemption.model');

            const [
                totalUsers,
                verifiedUsers,
                activePosts,
                pendingReports,
                pendingVerifications,
                resolvedReports,
                totalRecoveryPoints,
                totalRewardsRedeemed
            ] = await Promise.all([
                User.count(),
                User.count({ where: { verified: true } }).catch(() => User.count()), // Fallback if `is_verified` or `verified` differs
                Post.count({ where: { is_found: false, moderation_status: 'visible' } }).catch(() => Post.count()),
                Report.count({ where: { status: 'pending' } }),
                User.count({ where: { verification_status: 'pending' } }),
                Report.count({ where: { status: 'resolved' } }),
                User.sum('recovery_points').then(sum => sum || 0).catch(() => 0),
                RecoveryRedemption.count().catch(() => 0)
            ]);

            return response.Success(res, 'Admin stats retrieved successfully', {
                totalUsers,
                verifiedUsers,
                activePosts,
                pendingReports,
                pendingVerifications,
                resolvedReports,
                totalRecoveryPoints,
                totalRewardsRedeemed
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get all users with pagination
     */
    async getAllUsers(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;

            const result = await UserService.getAllUsers(limit, offset);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, {
                users: result.data,
                pagination: result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get specific user by ID
     */
    async getUserById(req, res) {
        try {
            const { userId } = req.params;
            const result = await UserService.getUserById(userId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Update any user profile/moderation fields
     */
    async updateUser(req, res) {
        try {
            const { userId } = req.params;
            const allowedStatuses = ['active', 'suspended', 'banned'];
            const allowedRoles = ['user', 'admin'];
            const allowedVerificationStatuses = ['not_submitted', 'pending', 'approved', 'rejected'];

            if (req.body.status && !allowedStatuses.includes(req.body.status)) {
                return response.ErrorResponse(res, 'Invalid status enum for user', null, 400);
            }

            if (req.body.role && !allowedRoles.includes(req.body.role)) {
                return response.ErrorResponse(res, 'Invalid role enum for user', null, 400);
            }

            if (req.body.verification_status && !allowedVerificationStatuses.includes(req.body.verification_status)) {
                return response.ErrorResponse(res, 'Invalid verification status enum for user', null, 400);
            }

            const result = await UserService.updateUserProfile(userId, req.body);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            return response.Success(res, 'User updated successfully', null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Delete any user (admin privilege)
     */
    async deleteUser(req, res) {
        try {
            const { userId } = req.params;
            const result = await UserService.adminDeleteUser(userId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Update any post (admin privilege)
     */
    async updatePost(req, res) {
        try {
            const { postId } = req.params;
            const updateData = req.body;

            if (updateData.post_type && !['lost', 'found'].includes(updateData.post_type)) {
                return response.ErrorResponse(res, 'Invalid post type enum', null, 400);
            }

            if (updateData.status && !['active', 'matched', 'closed', 'resolved'].includes(updateData.status)) {
                return response.ErrorResponse(res, 'Invalid post status enum', null, 400);
            }

            if (updateData.moderation_status && !['visible', 'hidden', 'removed'].includes(updateData.moderation_status)) {
                return response.ErrorResponse(res, 'Invalid moderation status enum for post', null, 400);
            }

            const result = await PostService.adminUpdatePost(postId, updateData);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Delete any post (admin privilege)
     */
    async deletePost(req, res) {
        try {
            const { postId } = req.params;
            const result = await PostService.adminDeletePost(postId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get all identity verifications with optional status filter (for history)
     */
    async getVerifications(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;
            const status = req.query.status || 'all';

            const result = await UserService.getVerifications(status, limit, offset);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, {
                verifications: result.data,
                pagination: result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get all pending identity verifications
     */
    async getPendingVerifications(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;

            const result = await UserService.getPendingVerifications(limit, offset);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, {
                verifications: result.data,
                pagination: result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Approve identity verification
     */
    async approveVerification(req, res) {
        try {
            const { userId } = req.params;
            const { notes } = req.body;

            const result = await UserService.approveVerification(userId, notes);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Reject identity verification
     */
    async rejectVerification(req, res) {
        try {
            const { userId } = req.params;
            const { notes } = req.body;

            const result = await UserService.rejectVerification(userId, notes);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
    /**
     * Update user account status
     */
    async updateUserStatus(req, res) {
        try {
            const { userId } = req.params;
            const { status, reason } = req.body;

            // Validate status
            if (!['active', 'suspended', 'banned'].includes(status)) {
                return response.ErrorResponse(res, 'Invalid status enum for user', null, 400);
            }

            const User = require('../models/User.model');
            await User.update({ 
                status,
                moderation_reason: reason,
                moderated_at: new Date()
            }, { where: { id: userId } });
            
            return response.Success(res, 'User status updated successfully', null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Update post moderation status
     */
    async updatePostModeration(req, res) {
        try {
            const { postId } = req.params;
            const { moderation_status } = req.body;

            // Validate status
            if (!['visible', 'hidden', 'removed'].includes(moderation_status)) {
                return response.ErrorResponse(res, 'Invalid moderation status enum for post', null, 400);
            }

            const Post = require('../models/post.model');
            await Post.update({ moderation_status }, { where: { id: postId } });
            
            return response.Success(res, 'Post visibility updated successfully', null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Admin manual point adjustment
     */
    async adjustUserPoints(req, res) {
        try {
            const { userId } = req.params;
            const { points, reason } = req.body;

            if (points === undefined || isNaN(parseInt(points))) {
                return response.ErrorResponse(res, 'Valid points parameter is required', null, 400);
            }

            const result = await RecoveryService.adminAdjustPoints(userId, parseInt(points), reason);
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, { currentPoints: result.currentPoints }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get full chat message history for admin review
     */
    async getChatMessages(req, res) {
        try {
            const { chatId } = req.params;
            const Chat = require('../models/Chat.model');
            const Message = require('../models/Message.model');
            const User = require('../models/User.model');

            // 1. Check if chat exists
            const chat = await Chat.findByPk(chatId, {
                include: [
                    { model: User, as: 'firstUser', attributes: ['id', 'name', 'email'] },
                    { model: User, as: 'secondUser', attributes: ['id', 'name', 'email'] }
                ]
            });

            if (!chat) {
                return response.ErrorResponse(res, 'Chat not found', null, 404);
            }

            // 2. Fetch all messages in the chat
            const messages = await Message.findAll({
                where: { chat_id: chatId },
                order: [['created_at', 'ASC']],
                include: [
                    { model: User, as: 'sender', attributes: ['id', 'name', 'email'] }
                ]
            });

            return response.Success(res, 'Chat messages retrieved successfully for admin audit', {
                chat,
                messages
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new AdminController();

