'use strict';

const { Op } = require('sequelize');
const sequelize = require('../db/Sequelize');
const { User, Post, ContactRequest, RecoveryPointTransaction, WalletRedemption } = require('../models');
const {
    FINDER_POINTS,
    OWNER_POINTS,
    TRANSACTION_REASONS,
    REDEMPTION_STATUSES,
    VALID_TIER_POINTS,
    VALID_WALLET_PROVIDERS,
    getTierByPoints,
    maskWalletNumber,
} = require('../config/rewards.config');

/**
 * ============================================================
 *  RecoveryService
 *  Handles all recovery-point earning, balance management,
 *  and wallet cash redemption logic.
 * ============================================================
 */
class RecoveryService {

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 1 — Recovery Point Award (called when a post is resolved)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Award 70 points to the finder and 30 points to the owner when a post
     * is successfully resolved with an accepted contact request.
     *
     * Rules:
     *   post_type = 'lost'  → poster is the owner (30 pts),
     *                          accepted contact sender is the finder (70 pts)
     *   post_type = 'found' → poster is the finder (70 pts),
     *                          accepted contact sender is the real owner (30 pts)
     *
     * This method is IDEMPOTENT — calling it twice for the same post is safe;
     * the second call returns early without writing anything.
     *
     * @param {string} postId
     * @returns {{ success: boolean, message: string, data?: object }}
     */
    async awardRecoveryPointsForPost(postId) {
        try {
            console.log(`[RecoveryService] Checking reward eligibility for post: ${postId}`);

            // ── 1. Idempotency guard ───────────────────────────────────────────
            // If either recovery reason already exists for this post, we have
            // already awarded points. Skip silently.
            const alreadyAwarded = await RecoveryPointTransaction.findOne({
                where: {
                    post_id: postId,
                    reason: {
                        [Op.in]: [
                            TRANSACTION_REASONS.FINDER_REWARD,
                            TRANSACTION_REASONS.OWNER_REWARD,
                        ]
                    }
                }
            });

            if (alreadyAwarded) {
                console.log(`[RecoveryService] Points already awarded for post ${postId}. Skipping.`);
                return { success: false, message: 'Points already awarded for this post' };
            }

            // ── 2. Fetch post with owner ───────────────────────────────────────
            const post = await Post.findByPk(postId, {
                include: [{ model: User, as: 'owner' }]
            });

            if (!post) {
                console.log(`[RecoveryService] Post not found: ${postId}`);
                return { success: false, message: 'Post not found' };
            }

            // ── 3. Verify post is actually resolved ───────────────────────────
            if (post.status !== 'resolved') {
                console.log(`[RecoveryService] Post ${postId} is not resolved (status=${post.status}). No points.`);
                return { success: false, message: 'Post is not in resolved state' };
            }

            // ── 4. Find accepted contact request ──────────────────────────────
            const acceptedRequest = await ContactRequest.findOne({
                where: { post_id: postId, status: 'accepted' },
                include: [
                    { model: User, as: 'sender' },
                    { model: User, as: 'receiver' }
                ]
            });

            if (!acceptedRequest) {
                console.log(`[RecoveryService] No accepted contact request for post ${postId}. No points.`);
                return { success: false, message: 'No accepted contact request found' };
            }

            // ── 5. Resolve who is finder and who is owner ─────────────────────
            const postOwnerId = post.user_id;

            // The "other party" in the contact request is whoever is NOT the post owner
            const otherPartyId =
                acceptedRequest.sender_id === postOwnerId
                    ? acceptedRequest.receiver_id
                    : acceptedRequest.sender_id;

            if (!otherPartyId) {
                console.log(`[RecoveryService] Cannot identify the other party for post ${postId}.`);
                return { success: false, message: 'Could not identify both parties' };
            }

            // Self-claim protection
            if (postOwnerId === otherPartyId) {
                console.log(`[RecoveryService] Self-claim detected for post ${postId}. Blocked.`);
                return { success: false, message: 'Self-claim point reward blocked' };
            }

            // Determine point amounts based on post type
            // lost post:  poster = owner → 30 pts,  other = finder → 70 pts
            // found post: poster = finder → 70 pts, other = real owner → 30 pts
            const isLostPost = (post.post_type || '').toLowerCase() === 'lost';

            const postOwnerPoints = isLostPost ? OWNER_POINTS  : FINDER_POINTS;  // 30 or 70
            const otherPartyPoints = isLostPost ? FINDER_POINTS : OWNER_POINTS;   // 70 or 30

            const postOwnerReason  = isLostPost
                ? TRANSACTION_REASONS.OWNER_REWARD
                : TRANSACTION_REASONS.FINDER_REWARD;

            const otherPartyReason = isLostPost
                ? TRANSACTION_REASONS.FINDER_REWARD
                : TRANSACTION_REASONS.OWNER_REWARD;

            // ── 6. Execute inside a DB transaction ────────────────────────────
            const result = await sequelize.transaction(async (t) => {

                // Award post owner
                await RecoveryPointTransaction.create({
                    user_id : postOwnerId,
                    post_id : postId,
                    points  : postOwnerPoints,
                    reason  : postOwnerReason,
                }, { transaction: t });

                await User.increment(
                    { recovery_points: postOwnerPoints },
                    { where: { id: postOwnerId }, transaction: t }
                );

                // Award other party
                await RecoveryPointTransaction.create({
                    user_id : otherPartyId,
                    post_id : postId,
                    points  : otherPartyPoints,
                    reason  : otherPartyReason,
                }, { transaction: t });

                await User.increment(
                    { recovery_points: otherPartyPoints },
                    { where: { id: otherPartyId }, transaction: t }
                );

                return { postOwnerPoints, otherPartyPoints };
            });

            const ownerLabel = isLostPost ? 'loser/owner' : 'finder (post owner)';
            const otherLabel = isLostPost ? 'finder (claimant)' : 'real owner (claimant)';

            console.log(`[RecoveryService] Awarded ${result.postOwnerPoints} pts to ${ownerLabel} (${postOwnerId})`);
            console.log(`[RecoveryService] Awarded ${result.otherPartyPoints} pts to ${otherLabel} (${otherPartyId})`);

            return {
                success : true,
                message : 'Recovery points awarded successfully',
                data    : {
                    postType          : post.post_type,
                    postOwnerPoints   : result.postOwnerPoints,
                    otherPartyPoints  : result.otherPartyPoints,
                    totalDistributed  : result.postOwnerPoints + result.otherPartyPoints,
                }
            };

        } catch (error) {
            console.error('[RecoveryService] Error awarding points:', error);
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 2 — User Points Queries
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Get user's current point balance + summary stats.
     * @param {string} userId
     */
    async getUserPointsSummary(userId) {
        try {
            const user = await User.findByPk(userId, {
                attributes: ['id', 'recovery_points']
            });

            if (!user) return { success: false, message: 'User not found' };

            // Total earned = sum of all positive transactions
            const earned = await RecoveryPointTransaction.sum('points', {
                where: { user_id: userId, points: { [Op.gt]: 0 } }
            }) || 0;

            // Total redeemed = abs of all negative transactions
            const redeemedNeg = await RecoveryPointTransaction.sum('points', {
                where: { user_id: userId, points: { [Op.lt]: 0 } }
            }) || 0;
            const redeemed = Math.abs(redeemedNeg);

            // Pending redemption count and EGP amount
            const pendingRedemptions = await WalletRedemption.findAll({
                where: { user_id: userId, status: REDEMPTION_STATUSES.PENDING },
                attributes: ['points_spent', 'cash_amount_egp']
            });

            const pendingCount  = pendingRedemptions.length;
            const pendingPoints = pendingRedemptions.reduce((s, r) => s + r.points_spent, 0);
            const pendingEgp    = pendingRedemptions.reduce((s, r) => s + r.cash_amount_egp, 0);

            return {
                success: true,
                data: {
                    current_balance       : user.recovery_points,
                    total_earned          : earned,
                    total_redeemed        : redeemed,
                    pending_redemptions   : pendingCount,
                    pending_points        : pendingPoints,
                    pending_egp           : pendingEgp,
                }
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get paginated points transaction history for a user.
     * @param {string} userId
     * @param {number} limit
     * @param {number} offset
     */
    async getUserPointTransactions(userId, limit = 30, offset = 0) {
        try {
            const rows = await RecoveryPointTransaction.findAll({
                where  : { user_id: userId },
                order  : [['created_at', 'DESC']],
                limit,
                offset,
                include: [{
                    model      : Post,
                    as         : 'associatedPost',
                    attributes : ['id', 'title', 'post_type'],
                    required   : false
                }]
            });

            return {
                success : true,
                data    : rows.map(tx => ({
                    id            : tx.id,
                    points        : tx.points,
                    reason        : tx.reason,
                    reason_label  : this._reasonLabel(tx.reason),
                    post          : tx.associatedPost
                        ? { id: tx.associatedPost.id, title: tx.associatedPost.title, type: tx.associatedPost.post_type }
                        : null,
                    created_at    : tx.created_at,
                }))
            };
        } catch (error) {
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 3 — Wallet Cash Redemption (User)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Create a cash redemption request.
     * Points are deducted immediately inside a DB transaction.
     * If the request is later rejected by an admin, points are refunded.
     *
     * @param {string} userId
     * @param {number} tierPoints   — must be one of [500, 1000, 1500, 2000]
     * @param {string} walletProvider
     * @param {string} walletNumber
     */
    async redeemCash(userId, tierPoints, walletProvider, walletNumber) {
        try {
            // ── Validate tier ──────────────────────────────────────────────────
            const tier = getTierByPoints(tierPoints);
            if (!tier) {
                return {
                    success : false,
                    message : `Invalid redemption tier. Allowed tiers: 500, 1000, 1500, 2000 points`
                };
            }

            // ── Validate wallet provider ───────────────────────────────────────
            if (!VALID_WALLET_PROVIDERS.has(walletProvider)) {
                return {
                    success : false,
                    message : `Invalid wallet provider. Allowed: vodafone_cash, orange_cash, etisalat_cash, instapay, other_wallet`
                };
            }

            // ── Validate wallet number ─────────────────────────────────────────
            const normalizedNumber = String(walletNumber || '').trim();
            if (!normalizedNumber) {
                return { success: false, message: 'Wallet number is required' };
            }

            // ── Check user balance ─────────────────────────────────────────────
            const user = await User.findByPk(userId, {
                attributes: ['id', 'name', 'recovery_points']
            });

            if (!user) return { success: false, message: 'User not found' };

            if (user.recovery_points < tier.points) {
                return {
                    success : false,
                    message : `Insufficient points. You need ${tier.points} pts but only have ${user.recovery_points} pts.`
                };
            }

            // ── Execute inside DB transaction ──────────────────────────────────
            const redemption = await sequelize.transaction(async (t) => {

                // 1. Create redemption request
                const req = await WalletRedemption.create({
                    user_id         : userId,
                    points_spent    : tier.points,
                    cash_amount_egp : tier.egp,
                    wallet_provider : walletProvider,
                    wallet_number   : normalizedNumber,
                    status          : REDEMPTION_STATUSES.PENDING,
                }, { transaction: t });

                // 2. Record negative point transaction linked to this redemption
                await RecoveryPointTransaction.create({
                    user_id      : userId,
                    post_id      : null,
                    points       : -tier.points,
                    reason       : TRANSACTION_REASONS.CASH_REDEMPTION,
                    redemption_id: req.id,
                }, { transaction: t });

                // 3. Deduct from user balance
                await User.decrement(
                    { recovery_points: tier.points },
                    { where: { id: userId }, transaction: t }
                );

                return req;
            });

            // Re-fetch updated balance
            const updatedUser = await User.findByPk(userId, { attributes: ['recovery_points'] });

            console.log(`[RecoveryService] User ${userId} redeemed ${tier.points} pts → ${tier.egp} EGP via ${walletProvider}`);

            return {
                success : true,
                message : `Redemption request submitted. ${tier.egp} EGP will be sent to your ${walletProvider} wallet.`,
                data    : {
                    redemption_id     : redemption.id,
                    points_spent      : tier.points,
                    cash_amount_egp   : tier.egp,
                    wallet_provider   : walletProvider,
                    wallet_number_masked: maskWalletNumber(normalizedNumber),
                    status            : REDEMPTION_STATUSES.PENDING,
                    new_balance       : updatedUser.recovery_points,
                    created_at        : redemption.created_at,
                }
            };

        } catch (error) {
            console.error('[RecoveryService] Error in redeemCash:', error);
            throw error;
        }
    }

    /**
     * Get wallet redemption history for a user.
     * @param {string} userId
     * @param {number} limit
     * @param {number} offset
     */
    async getUserRedemptions(userId, limit = 30, offset = 0) {
        try {
            const rows = await WalletRedemption.findAll({
                where   : { user_id: userId },
                order   : [['created_at', 'DESC']],
                limit,
                offset,
                include : [{
                    model      : User,
                    as         : 'processedBy',
                    attributes : ['id', 'name'],
                    required   : false
                }]
            });

            return {
                success : true,
                data    : rows.map(r => this._formatRedemption(r))
            };
        } catch (error) {
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 4 — Admin Redemption Management
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * List all redemption requests (admin).
     * @param {{ status?: string, limit?: number, offset?: number }} options
     */
    async listAllRedemptions({ status, limit = 50, offset = 0 } = {}) {
        try {
            const where = {};
            if (status && status !== 'all') {
                if (!Object.values(REDEMPTION_STATUSES).includes(status)) {
                    return { success: false, message: 'Invalid status filter' };
                }
                where.status = status;
            }

            const { count, rows } = await WalletRedemption.findAndCountAll({
                where,
                order  : [['created_at', 'DESC']],
                limit,
                offset,
                include: [
                    {
                        model      : User,
                        as         : 'user',
                        attributes : ['id', 'name', 'email', 'phone_number']
                    },
                    {
                        model      : User,
                        as         : 'processedBy',
                        attributes : ['id', 'name'],
                        required   : false
                    }
                ]
            });

            return {
                success    : true,
                data       : rows.map(r => this._formatRedemption(r, true)),
                pagination : { total: count, limit, offset, hasMore: offset + limit < count }
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get a single redemption by ID (admin).
     * @param {string} redemptionId
     */
    async getRedemptionById(redemptionId) {
        try {
            const redemption = await WalletRedemption.findByPk(redemptionId, {
                include: [
                    { model: User, as: 'user',        attributes: ['id', 'name', 'email', 'phone_number', 'recovery_points'] },
                    { model: User, as: 'processedBy', attributes: ['id', 'name'], required: false }
                ]
            });

            if (!redemption) return { success: false, message: 'Redemption not found' };

            return { success: true, data: this._formatRedemption(redemption, true) };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Approve a pending redemption (admin).
     * Does NOT refund or deduct — just marks as approved pending actual payout.
     * @param {string} redemptionId
     * @param {string} adminId
     */
    async approveRedemption(redemptionId, adminId) {
        try {
            const redemption = await WalletRedemption.findByPk(redemptionId);
            if (!redemption) return { success: false, message: 'Redemption not found' };

            if (redemption.status !== REDEMPTION_STATUSES.PENDING) {
                return { success: false, message: `Cannot approve a redemption with status: ${redemption.status}` };
            }

            await redemption.update({
                status               : REDEMPTION_STATUSES.APPROVED,
                processed_by_admin_id: adminId
            });

            return { success: true, message: 'Redemption approved successfully' };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Mark a redemption as paid (admin — after actual cash transfer).
     * @param {string} redemptionId
     * @param {string} adminId
     */
    async markRedemptionPaid(redemptionId, adminId) {
        try {
            const redemption = await WalletRedemption.findByPk(redemptionId);
            if (!redemption) return { success: false, message: 'Redemption not found' };

            if (redemption.status !== REDEMPTION_STATUSES.APPROVED) {
                return { success: false, message: `Can only mark APPROVED redemptions as paid. Current status: ${redemption.status}` };
            }

            await redemption.update({
                status               : REDEMPTION_STATUSES.PAID,
                paid_at              : new Date(),
                processed_by_admin_id: adminId
            });

            return { success: true, message: 'Redemption marked as paid' };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Reject a redemption and automatically refund the points (admin).
     * This is the user-friendly policy: points are refunded on rejection.
     * The refund is wrapped in a DB transaction for safety.
     *
     * @param {string} redemptionId
     * @param {string} adminId
     * @param {string} reason
     */
    async rejectRedemption(redemptionId, adminId, reason) {
        try {
            const redemption = await WalletRedemption.findByPk(redemptionId);
            if (!redemption) return { success: false, message: 'Redemption not found' };

            if (![REDEMPTION_STATUSES.PENDING, REDEMPTION_STATUSES.APPROVED].includes(redemption.status)) {
                return { success: false, message: `Cannot reject a redemption with status: ${redemption.status}` };
            }

            // Points refund inside a transaction
            await sequelize.transaction(async (t) => {

                // 1. Update redemption status
                await redemption.update({
                    status               : REDEMPTION_STATUSES.REJECTED,
                    failure_reason       : reason || 'Rejected by admin',
                    processed_by_admin_id: adminId
                }, { transaction: t });

                // 2. Restore user's points balance
                await User.increment(
                    { recovery_points: redemption.points_spent },
                    { where: { id: redemption.user_id }, transaction: t }
                );

                // 3. Create a refund transaction record for the ledger
                await RecoveryPointTransaction.create({
                    user_id      : redemption.user_id,
                    post_id      : null,
                    points       : redemption.points_spent,    // positive = refund
                    reason       : TRANSACTION_REASONS.CASH_REFUND,
                    redemption_id: redemption.id,
                }, { transaction: t });
            });

            console.log(`[RecoveryService] Rejected redemption ${redemptionId}; refunded ${redemption.points_spent} pts to user ${redemption.user_id}`);

            return {
                success : true,
                message : `Redemption rejected. ${redemption.points_spent} points have been refunded to the user.`
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Cancel a pending redemption (admin or user — before processing).
     * Also refunds points.
     * @param {string} redemptionId
     * @param {string} adminId
     */
    async cancelRedemption(redemptionId, adminId) {
        try {
            const redemption = await WalletRedemption.findByPk(redemptionId);
            if (!redemption) return { success: false, message: 'Redemption not found' };

            if (redemption.status !== REDEMPTION_STATUSES.PENDING) {
                return { success: false, message: `Can only cancel PENDING redemptions. Current status: ${redemption.status}` };
            }

            await sequelize.transaction(async (t) => {
                await redemption.update({
                    status               : REDEMPTION_STATUSES.CANCELLED,
                    processed_by_admin_id: adminId || null
                }, { transaction: t });

                await User.increment(
                    { recovery_points: redemption.points_spent },
                    { where: { id: redemption.user_id }, transaction: t }
                );

                await RecoveryPointTransaction.create({
                    user_id      : redemption.user_id,
                    post_id      : null,
                    points       : redemption.points_spent,
                    reason       : TRANSACTION_REASONS.CASH_REFUND,
                    redemption_id: redemption.id,
                }, { transaction: t });
            });

            return { success: true, message: 'Redemption cancelled and points refunded.' };
        } catch (error) {
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 5 — Admin Points Adjustment
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Manually adjust a user's point balance (admin).
     * @param {string} userId
     * @param {number} points   — positive to add, negative to subtract
     * @param {string} [reason]
     */
    async adminAdjustPoints(userId, points, reason) {
        try {
            const user = await User.findByPk(userId);
            if (!user) return { success: false, message: 'User not found' };

            if (typeof points !== 'number' || isNaN(points) || points === 0) {
                return { success: false, message: 'Points must be a non-zero number' };
            }

            await sequelize.transaction(async (t) => {
                await RecoveryPointTransaction.create({
                    user_id : userId,
                    post_id : null,
                    points  : points,
                    reason  : TRANSACTION_REASONS.ADMIN_ADJUSTMENT,
                }, { transaction: t });

                if (points > 0) {
                    await User.increment({ recovery_points: points }, { where: { id: userId }, transaction: t });
                } else {
                    await User.decrement({ recovery_points: Math.abs(points) }, { where: { id: userId }, transaction: t });
                }
            });

            const updatedUser = await User.findByPk(userId, { attributes: ['recovery_points'] });

            return {
                success       : true,
                message       : 'Points adjusted successfully',
                currentPoints : updatedUser.recovery_points
            };
        } catch (error) {
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 6 — Private Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Format a WalletRedemption model instance for API responses.
     * @param {object} r           — Sequelize instance
     * @param {boolean} adminView  — include unmasked number and user info for admin
     */
    _formatRedemption(r, adminView = false) {
        const base = {
            id                  : r.id,
            points_spent        : r.points_spent,
            cash_amount_egp     : r.cash_amount_egp,
            wallet_provider     : r.wallet_provider,
            wallet_number_masked: maskWalletNumber(r.wallet_number),
            status              : r.status,
            failure_reason      : r.failure_reason,
            paid_at             : r.paid_at,
            created_at          : r.created_at,
            updated_at          : r.updated_at,
            processed_by        : r.processedBy ? { id: r.processedBy.id, name: r.processedBy.name } : null,
        };

        if (adminView) {
            // Admin sees full wallet number and user details
            base.wallet_number = r.wallet_number;
            if (r.user) {
                base.user = {
                    id    : r.user.id,
                    name  : r.user.name,
                    email : r.user.email,
                    phone : r.user.phone_number,
                };
            }
        }

        return base;
    }

    /**
     * Human-readable label for a transaction reason code.
     * @param {string} reason
     */
    _reasonLabel(reason) {
        const labels = {
            [TRANSACTION_REASONS.FINDER_REWARD]   : 'Recovery reward — Finder',
            [TRANSACTION_REASONS.OWNER_REWARD]    : 'Recovery reward — Owner',
            [TRANSACTION_REASONS.CASH_REDEMPTION] : 'Cash redemption',
            [TRANSACTION_REASONS.CASH_REFUND]     : 'Cash redemption refund',
            [TRANSACTION_REASONS.ADMIN_ADJUSTMENT]: 'Admin adjustment',
        };
        return labels[reason] ?? reason.replace(/_/g, ' ');
    }
}

module.exports = new RecoveryService();
