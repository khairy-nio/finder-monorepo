'use strict';

const response = require('../utils/response.util');
const UserService = require('../services/user.service');
const PostService = require('../services/Post.service');
const RecoveryService = require('../services/recovery.service');
const reportService = require('../services/report.service');

class AdminController {

    // ──────────────────────────────────────────────────────────────────────────
    // Dashboard
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * GET /api/v1/admin/stats
     * Get lightweight admin dashboard overview statistics.
     */
    async getAdminStats(req, res) {
        try {
            const User            = require('../models/User.model');
            const Post            = require('../models/post.model');
            const Report          = require('../models/Report.model');
            const UserVerification = require('../models/UserVerification.model');
            const WalletRedemption = require('../models/RecoveryRedemption.model');

            const [
                totalUsers,
                verifiedUsers,
                activePosts,
                pendingReports,
                pendingVerifications,
                resolvedReports,
                totalRecoveryPoints,
                totalRedemptionsCount,
                pendingRedemptionsCount
            ] = await Promise.all([
                User.count(),
                User.count({ where: { verified: true } }).catch(() => User.count()),
                Post.count({ where: { status: 'active', moderation_status: 'visible' } }).catch(() => Post.count()),
                Report.count({ where: { status: 'pending' } }),
                User.count({ where: { verification_status: 'pending' } }),
                Report.count({ where: { status: 'resolved' } }),
                User.sum('recovery_points').then(s => s || 0).catch(() => 0),
                WalletRedemption.count().catch(() => 0),
                WalletRedemption.count({ where: { status: 'pending' } }).catch(() => 0)
            ]);

            return response.Success(res, 'Admin stats retrieved successfully', {
                totalUsers,
                verifiedUsers,
                activePosts,
                pendingReports,
                pendingVerifications,
                resolvedReports,
                totalRecoveryPoints,
                totalRedemptionsCount,
                pendingRedemptionsCount
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Users
    // ──────────────────────────────────────────────────────────────────────────

    async getAllUsers(req, res) {
        try {
            const limit  = parseInt(req.query.limit)  || 50;
            const offset = parseInt(req.query.offset) || 0;

            const result = await UserService.getAllUsers(limit, offset);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);

            return response.Success(res, result.message, {
                users      : result.data,
                pagination : result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async getUserById(req, res) {
        try {
            const { userId } = req.params;
            const result = await UserService.getUserById(userId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async updateUser(req, res) {
        try {
            const { userId } = req.params;
            const allowedStatuses             = ['active', 'suspended', 'banned'];
            const allowedRoles                = ['user', 'admin'];
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
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, 'User updated successfully', null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async deleteUser(req, res) {
        try {
            const { userId } = req.params;
            const result = await UserService.adminDeleteUser(userId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Posts
    // ──────────────────────────────────────────────────────────────────────────

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
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async deletePost(req, res) {
        try {
            const { postId } = req.params;
            const result = await PostService.adminDeletePost(postId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async getAllPosts(req, res) {
        try {
            const { limit, offset, type, status, moderation_status } = req.query;
            const result = await PostService.getFilteredPosts({
                limit             : parseInt(limit) || 100,
                offset            : parseInt(offset) || 0,
                type,
                status,
                moderation_status : moderation_status || 'all'
            });
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, 'Posts retrieved successfully', {
                posts      : result.data,
                pagination : result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Identity Verification
    // ──────────────────────────────────────────────────────────────────────────

    async getVerifications(req, res) {
        try {
            const limit  = parseInt(req.query.limit)  || 50;
            const offset = parseInt(req.query.offset) || 0;
            const status = req.query.status || 'all';

            const result = await UserService.getVerifications(status, limit, offset);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);

            return response.Success(res, result.message, {
                verifications : result.data,
                pagination    : result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async getPendingVerifications(req, res) {
        try {
            const limit  = parseInt(req.query.limit)  || 50;
            const offset = parseInt(req.query.offset) || 0;

            const result = await UserService.getPendingVerifications(limit, offset);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);

            return response.Success(res, result.message, {
                verifications : result.data,
                pagination    : result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async approveVerification(req, res) {
        try {
            const { userId } = req.params;
            const { notes }  = req.body;
            const result = await UserService.approveVerification(userId, notes);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async rejectVerification(req, res) {
        try {
            const { userId } = req.params;
            const { notes }  = req.body;
            const result = await UserService.rejectVerification(userId, notes);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // User Moderation
    // ──────────────────────────────────────────────────────────────────────────

    async updateUserStatus(req, res) {
        try {
            const { userId }          = req.params;
            const { status, reason }  = req.body;

            if (!['active', 'suspended', 'banned'].includes(status)) {
                return response.ErrorResponse(res, 'Invalid status enum for user', null, 400);
            }

            const User = require('../models/User.model');
            await User.update({
                status,
                moderation_reason : reason,
                moderated_at      : new Date()
            }, { where: { id: userId } });

            return response.Success(res, 'User status updated successfully', null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async updatePostModeration(req, res) {
        try {
            const { postId }           = req.params;
            const { moderation_status } = req.body;

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

    // ──────────────────────────────────────────────────────────────────────────
    // Recovery Points — Manual Adjustment
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * POST /api/v1/admin/users/:userId/points/adjust
     * Manually add or subtract points from a user's balance.
     * Body: { points: number, reason?: string }
     */
    async adjustUserPoints(req, res) {
        try {
            const { userId }      = req.params;
            const { points }      = req.body;

            if (points === undefined || isNaN(parseInt(points))) {
                return response.ErrorResponse(res, 'Valid points parameter is required', null, 400);
            }

            const result = await RecoveryService.adminAdjustPoints(userId, parseInt(points));
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);

            return response.Success(res, result.message, { currentPoints: result.currentPoints }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Wallet Cash Redemption Management (Admin)
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * GET /api/v1/admin/redemptions
     * List all wallet cash redemption requests.
     * Query params: ?status=pending|approved|paid|rejected|cancelled|all&limit=50&offset=0
     */
    async getRedemptions(req, res) {
        try {
            const { status } = req.query;
            const limit  = parseInt(req.query.limit)  || 50;
            const offset = parseInt(req.query.offset) || 0;

            const result = await RecoveryService.listAllRedemptions({ status, limit, offset });
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);

            return response.Success(res, 'Redemption requests retrieved successfully', {
                redemptions : result.data,
                pagination  : result.pagination
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/admin/redemptions/:redemptionId
     * Get details of a single redemption request.
     */
    async getRedemptionById(req, res) {
        try {
            const { redemptionId } = req.params;
            const result = await RecoveryService.getRedemptionById(redemptionId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, 'Redemption details retrieved', result.data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * POST /api/v1/admin/redemptions/:redemptionId/approve
     * Approve a pending redemption request (admin confirms intent to pay).
     */
    async approveRedemption(req, res) {
        try {
            const { redemptionId } = req.params;
            const adminId          = req.user.id;

            const result = await RecoveryService.approveRedemption(redemptionId, adminId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * POST /api/v1/admin/redemptions/:redemptionId/paid
     * Mark an approved redemption as paid (after actual wallet transfer).
     */
    async markRedemptionPaid(req, res) {
        try {
            const { redemptionId } = req.params;
            const adminId          = req.user.id;

            const result = await RecoveryService.markRedemptionPaid(redemptionId, adminId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * POST /api/v1/admin/redemptions/:redemptionId/reject
     * Reject a redemption request and automatically refund the user's points.
     * Body: { reason: string } (required)
     */
    async rejectRedemption(req, res) {
        try {
            const { redemptionId } = req.params;
            const adminId          = req.user.id;
            const { reason }       = req.body;

            const result = await RecoveryService.rejectRedemption(redemptionId, adminId, reason);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * POST /api/v1/admin/redemptions/:redemptionId/cancel
     * Cancel a pending redemption and refund the user's points.
     */
    async cancelRedemption(req, res) {
        try {
            const { redemptionId } = req.params;
            const adminId          = req.user.id;

            const result = await RecoveryService.cancelRedemption(redemptionId, adminId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 400);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Reports
    // ──────────────────────────────────────────────────────────────────────────

    async getAllReports(req, res) {
        try {
            const { limit, offset, status } = req.query;
            const data = await reportService.getAllReports(
                parseInt(limit)  || 100,
                parseInt(offset) || 0,
                status
            );
            return response.Success(res, 'Reports retrieved successfully', data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Chat Audit
    // ──────────────────────────────────────────────────────────────────────────

    async getChatMessages(req, res) {
        try {
            const { chatId } = req.params;
            const Chat    = require('../models/Chat.model');
            const Message = require('../models/Message.model');
            const User    = require('../models/User.model');

            const chat = await Chat.findByPk(chatId, {
                include: [
                    { model: User, as: 'firstUser',  attributes: ['id', 'name', 'email'] },
                    { model: User, as: 'secondUser', attributes: ['id', 'name', 'email'] }
                ]
            });

            if (!chat) return response.ErrorResponse(res, 'Chat not found', null, 404);

            const messages = await Message.findAll({
                where   : { chat_id: chatId },
                order   : [['created_at', 'ASC']],
                include : [{ model: User, as: 'sender', attributes: ['id', 'name', 'email'] }]
            });

            return response.Success(res, 'Chat messages retrieved successfully for admin audit', {
                chat,
                messages
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Notifications
    // ──────────────────────────────────────────────────────────────────────────

    async getNotifications(_req, res) {
        try {
            const User   = require('../models/User.model');
            const Report = require('../models/Report.model');
            const WalletRedemption = require('../models/RecoveryRedemption.model');

            const [pendingVerifications, pendingReports, pendingRedemptions] = await Promise.all([
                User.findAll({
                    where      : { verification_status: 'pending' },
                    attributes : ['id', 'name', 'email', 'verification_submitted_at'],
                    order      : [['verification_submitted_at', 'DESC']],
                    limit      : 10
                }),
                Report.findAll({
                    where      : { status: 'pending' },
                    attributes : ['id', 'reportType', 'reason', 'created_at'],
                    order      : [['created_at', 'DESC']],
                    limit      : 10
                }),
                WalletRedemption.findAll({
                    where      : { status: 'pending' },
                    attributes : ['id', 'cash_amount_egp', 'wallet_provider', 'created_at'],
                    order      : [['created_at', 'DESC']],
                    limit      : 10
                })
            ]);

            const items = [
                ...pendingVerifications.map(u => ({
                    id        : `verify-${u.id}`,
                    type      : 'verification',
                    title     : 'Verification Request',
                    body      : `${u.name || u.email} submitted identity documents`,
                    link      : '/verification',
                    createdAt : u.verification_submitted_at
                })),
                ...pendingReports.map(r => ({
                    id        : `report-${r.id}`,
                    type      : 'report',
                    title     : 'New Report',
                    body      : `${r.reportType || 'Report'}: ${(r.reason || '').slice(0, 60)}`,
                    link      : '/reports',
                    createdAt : r.created_at
                })),
                ...pendingRedemptions.map(d => ({
                    id        : `redemption-${d.id}`,
                    type      : 'redemption',
                    title     : 'Cash Redemption Request',
                    body      : `${d.cash_amount_egp} EGP via ${d.wallet_provider}`,
                    link      : '/redemptions',
                    createdAt : d.created_at
                }))
            ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

            return response.Success(res, 'Notifications retrieved', {
                total : items.length,
                items
            }, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new AdminController();
