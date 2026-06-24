'use strict';

const response = require('../utils/response.util');
const UserService = require('../services/user.service');
const RecoveryService = require('../services/recovery.service');
const { REDEMPTION_TIERS, WALLET_PROVIDERS, POINTS_PER_EGP } = require('../config/rewards.config');

class UserController {

    // ──────────────────────────────────────────────────────────────────────────
    // Profile
    // ──────────────────────────────────────────────────────────────────────────

    async getprofile(req, res) {
        try {
            const userId = req.user.id;
            const result = await UserService.getUserById(userId);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            return response.Success(res, result.message, result.data, 200);
        } catch (err) {
            console.error('Error in getprofile:', err);
            return response.ErrorResponse(res, 'Internal Server Error', err.message, 500);
        }
    }

    async editprofile(req, res) {
        try {
            const userId = req.user.id;
            const { name, phone_number, country, state, city, area, selfie_image_url, bio } = req.body;

            const updateResult = await UserService.updateUserProfile(userId, {
                name,
                phone_number,
                country,
                state,
                city,
                area,
                selfie_image_url,
                bio
            });

            if (!updateResult.success) {
                return response.ErrorResponse(res, updateResult.message, null, 400);
            }

            return response.Success(res, updateResult.message, null, 200);
        } catch (err) {
            console.error('Error in editprofile:', err);
            return response.ErrorResponse(res, 'Internal server error', err.message, 500);
        }
    }

    async deleteprofile(req, res) {
        try {
            const userId = req.user.id;
            const deleteResult = await UserService.deleteUser(userId);

            if (!deleteResult.success) {
                return response.ErrorResponse(res, deleteResult.message, null, 400);
            }

            return response.Success(res, deleteResult.message, null, 200);
        } catch (err) {
            console.error('Error in deleteprofile:', err);
            return response.ErrorResponse(res, 'Internal server error', err.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Identity Verification
    // ──────────────────────────────────────────────────────────────────────────

    async submitVerification(req, res) {
        try {
            const userId = req.user.id;
            const { national_id, phone_number, id_image_url, selfie_image_url, verification_location } = req.body;

            const result = await UserService.submitVerification(
                userId,
                national_id,
                phone_number,
                id_image_url,
                selfie_image_url,
                verification_location
            );

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, null, 200);
        } catch (error) {
            console.error('Error in submitVerification:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async getVerificationStatus(req, res) {
        try {
            const userId = req.user.id;
            const result = await UserService.getVerificationStatus(userId);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in getVerificationStatus:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Recovery Points — Balance & History
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * GET /api/v1/user/me/points
     * Returns the user's current point balance plus summary stats.
     * Mobile app uses this for the "Wallet" tab header.
     */
    async getPointsSummary(req, res) {
        try {
            const userId = req.user.id;
            const result = await RecoveryService.getUserPointsSummary(userId);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            return response.Success(res, 'Points summary retrieved successfully', result.data, 200);
        } catch (error) {
            console.error('Error in getPointsSummary:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/user/me/points/history
     * Returns the user's paginated points transaction history.
     */
    async getPointsHistory(req, res) {
        try {
            const userId = req.user.id;
            const limit  = parseInt(req.query.limit)  || 30;
            const offset = parseInt(req.query.offset) || 0;

            const result = await RecoveryService.getUserPointTransactions(userId, limit, offset);

            return response.Success(res, 'Point transactions retrieved successfully', result.data, 200);
        } catch (error) {
            console.error('Error in getPointsHistory:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/user/me/points/tiers
     * Returns the available cash redemption tiers.
     * This is a static list — no DB call needed.
     * Mobile app uses this to populate the "Cash Out" tab.
     */
    async getAvailableTiers(req, res) {
        return response.Success(res, 'Cash redemption tiers retrieved', {
            points_per_egp   : POINTS_PER_EGP,
            wallet_providers : WALLET_PROVIDERS,
            tiers            : REDEMPTION_TIERS.map(t => ({
                points          : t.points,
                cash_amount_egp : t.egp,
                label           : `${t.egp} EGP`,
                description     : `Redeem ${t.points} points for ${t.egp} EGP wallet cash`,
            })),
        }, 200);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Cash Redemption — User Actions
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * POST /api/v1/user/me/redeem
     * Submit a wallet cash redemption request.
     *
     * Body: { tier_points, wallet_provider, wallet_number }
     */
    async redeemCash(req, res) {
        try {
            const userId = req.user.id;
            const { tier_points, wallet_provider, wallet_number } = req.body;

            const result = await RecoveryService.redeemCash(
                userId,
                parseInt(tier_points),
                wallet_provider,
                wallet_number
            );

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, result.data, 201);
        } catch (error) {
            console.error('Error in redeemCash:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/user/me/redemptions
     * Get the user's wallet cash redemption history.
     */
    async getRedemptionsHistory(req, res) {
        try {
            const userId = req.user.id;
            const limit  = parseInt(req.query.limit)  || 30;
            const offset = parseInt(req.query.offset) || 0;

            const result = await RecoveryService.getUserRedemptions(userId, limit, offset);

            return response.Success(res, 'Redemption history retrieved successfully', result.data, 200);
        } catch (error) {
            console.error('Error in getRedemptionsHistory:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new UserController();
