const { User, Post, ContactRequest, RecoveryPointTransaction, RecoveryRedemption } = require('../models');
const { Op } = require('sequelize');

class RecoveryService {
    /**
     * Award recovery points when a post is successfully resolved with an accepted claim request
     */
    async awardRecoveryPointsForPost(postId) {
        try {
            console.log(`[RecoveryService] Checking rewards for post: ${postId}`);

            // 1. Prevent duplicate rewards (anti-farming protection)
            const existingTx = await RecoveryPointTransaction.findOne({
                where: {
                    post_id: postId,
                    reason: 'successful_recovery'
                }
            });

            if (existingTx) {
                console.log(`[RecoveryService] Points already awarded for post: ${postId}. Skipping.`);
                return { success: false, message: 'Points already awarded for this post' };
            }

            // 2. Fetch post with owner
            const post = await Post.findByPk(postId, {
                include: [{ model: User, as: 'owner' }]
            });

            if (!post) {
                console.log(`[RecoveryService] Post not found: ${postId}`);
                return { success: false, message: 'Post not found' };
            }

            // 3. Find accepted contact request (ensures legitimate resolution)
            const contactRequest = await ContactRequest.findOne({
                where: {
                    post_id: postId,
                    status: 'accepted'
                }
            });

            if (!contactRequest) {
                console.log(`[RecoveryService] No accepted contact request found for post: ${postId}. No points awarded.`);
                return { success: false, message: 'No accepted claim request exists' };
            }

            // 4. Identify helper (claimant) and owner
            const ownerId = post.user_id;
            const claimantId = contactRequest.sender_id === ownerId 
                ? contactRequest.receiver_id 
                : contactRequest.sender_id;

            // Fetch claimant
            const claimant = await User.findByPk(claimantId);
            const owner = post.owner;

            if (!owner || !claimant) {
                console.log(`[RecoveryService] Owner or claimant missing. Skipping point reward.`);
                return { success: false, message: 'Owner or helper missing' };
            }

            // Prevent self-claims / gaming the system
            if (ownerId === claimantId) {
                console.log(`[RecoveryService] Owner and helper are the same user (${ownerId}). Self-claim points blocked.`);
                return { success: false, message: 'Self-claim point reward blocked' };
            }

            // 5. Determine point values based on post type
            let ownerPoints = 0;
            let claimantPoints = 0;

            const isLostItem = (post.postType || post.type || '').toLowerCase() === 'lost';

            if (isLostItem) {
                // Lost-item recovery: post owner recovered their lost item, claimant is the finder/helper
                ownerPoints = 100;    // +100 to owner
                claimantPoints = 50;  // +50 to helper
            } else {
                // Found-item resolution: post owner found the item and returned it to the claimant (the real owner)
                ownerPoints = 50;     // +50 to finder (owner of post)
                claimantPoints = 20;  // +20 to real owner who claimed it
            }

            // 6. Verified user bonus multiplier (+20% bonus)
            if (owner.verified) {
                ownerPoints = Math.round(ownerPoints * 1.2);
            }
            if (claimant.verified) {
                claimantPoints = Math.round(claimantPoints * 1.2);
            }

            // 7. Store transactions & update user balances
            // Award owner points
            if (ownerPoints > 0) {
                await RecoveryPointTransaction.create({
                    user_id: ownerId,
                    post_id: postId,
                    points: ownerPoints,
                    reason: 'successful_recovery'
                });
                await User.increment({ recovery_points: ownerPoints }, { where: { id: ownerId } });
                console.log(`[RecoveryService] Awarded ${ownerPoints} points to owner ${owner.name}`);
            }

            // Award claimant points
            if (claimantPoints > 0) {
                await RecoveryPointTransaction.create({
                    user_id: claimantId,
                    post_id: postId,
                    points: claimantPoints,
                    reason: 'successful_recovery'
                });
                await User.increment({ recovery_points: claimantPoints }, { where: { id: claimantId } });
                console.log(`[RecoveryService] Awarded ${claimantPoints} points to helper ${claimant.name}`);
            }

            return {
                success: true,
                message: 'Recovery points awarded successfully',
                data: {
                    ownerRewarded: ownerPoints,
                    claimantRewarded: claimantPoints
                }
            };
        } catch (error) {
            console.error('[RecoveryService] Error awarding points:', error);
            throw error;
        }
    }

    /**
     * Get transaction history for a user
     */
    async getUserPointTransactions(userId) {
        try {
            return await RecoveryPointTransaction.findAll({
                where: { user_id: userId },
                order: [['created_at', 'DESC']],
                include: [{
                    model: Post,
                    as: 'associatedPost',
                    attributes: ['id', 'title']
                }]

            });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get redemption history for a user
     */
    async getUserRedemptions(userId) {
        try {
            return await RecoveryRedemption.findAll({
                where: { user_id: userId },
                order: [['created_at', 'DESC']]
            });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Redeem a catalog reward
     */
    async redeemReward(userId, rewardId) {
        try {
            // Reward catalog definitions
            const catalog = {
                'amazon_10': { title: 'Amazon Gift Card $10', cost: 100 },
                'amazon_25': { title: 'Amazon Gift Card $25', cost: 220 },
                'carrefour_50': { title: 'Carrefour Shopping Coupon', cost: 80 },
                'gold_badge': { title: 'Gold Community Contributor Badge', cost: 40 }
            };

            const reward = catalog[rewardId];
            if (!reward) {
                return { success: false, message: 'Invalid reward selection' };
            }

            const user = await User.findByPk(userId);
            if (!user) {
                return { success: false, message: 'User not found' };
            }

            if (user.recovery_points < reward.cost) {
                return { 
                    success: false, 
                    message: `Insufficient points. You need ${reward.cost} points to redeem this, but you only have ${user.recovery_points}.` 
                };
            }

            // Create negative point transaction to log spend
            await RecoveryPointTransaction.create({
                user_id: userId,
                points: -reward.cost,
                reason: `redeem_${rewardId}`
            });

            // Deduct points from user
            await User.decrement({ recovery_points: reward.cost }, { where: { id: userId } });

            // Log redemption
            const redemption = await RecoveryRedemption.create({
                user_id: userId,
                reward_id: rewardId,
                reward_title: reward.title,
                points_spent: reward.cost,
                status: 'completed'
            });

            // Re-fetch user to get latest points
            const updatedUser = await User.findByPk(userId);

            return {
                success: true,
                message: `Successfully redeemed ${reward.title}!`,
                data: {
                    redemption,
                    currentPoints: updatedUser.recovery_points
                }
            };
        } catch (error) {
            console.error('[RecoveryService] Error redeeming reward:', error);
            throw error;
        }
    }

    /**
     * Admin manual adjustment of user points
     */
    async adminAdjustPoints(userId, points, reason) {
        try {
            const user = await User.findByPk(userId);
            if (!user) {
                return { success: false, message: 'User not found' };
            }

            await RecoveryPointTransaction.create({
                user_id: userId,
                points: points,
                reason: reason || 'admin_adjustment'
            });

            if (points > 0) {
                await User.increment({ recovery_points: points }, { where: { id: userId } });
            } else {
                await User.decrement({ recovery_points: Math.abs(points) }, { where: { id: userId } });
            }

            const updatedUser = await User.findByPk(userId);
            return {
                success: true,
                message: 'Points adjusted successfully',
                currentPoints: updatedUser.recovery_points
            };
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new RecoveryService();
