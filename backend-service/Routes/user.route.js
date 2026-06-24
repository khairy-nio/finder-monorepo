const authController = require('../Controllers/auth.controller');
const UserController = require('../Controllers/User.controller');
const response = require('../utils/response.util');
const { verfyFirebaseToken, verfyFirebaseTokenLite } = require('../Middlewares/auth.middleware');
const { requireAuthentication } = require('../Middlewares/isVerfied.middleware');
const { createUserValidator, updateUserValidator } = require('../validators/user.validator');
const { submitVerificationValidator } = require('../validators/verification.validator');
const { createRedemptionValidator } = require('../validators/redemption.validator');
const { uploadKycMiddleware, uploadVerificationToCloudinary } = require('../Middlewares/multer.middleware');
const validate = require('../Middlewares/validation');
const express = require('express');
const Router = express.Router();

/**
 * @route   POST /api/v1/user/login
 * @desc    Login or register user after Firebase authentication
 * @access  Public (requires Firebase token)
 */
Router.post('/login',
    verfyFirebaseTokenLite,
    createUserValidator,
    validate,
    authController.login);

Router.use(verfyFirebaseToken);
Router.use(requireAuthentication);

/**
 * @route   GET /api/v1/user/me
 * @desc    Get current user profile
 * @access  Private
 */
Router.get('/me', UserController.getprofile);

/**
 * @route   POST /api/v1/user/upload-image
 * @desc    Upload an image (profile / selfie)
 * @access  Private
 */
const { uploadMiddleware, uploadToCloudinary } = require('../Middlewares/multer.middleware');
Router.post('/upload-image',
    uploadMiddleware,
    uploadToCloudinary,
    (req, res) => {
        if (!req.body.image_url) {
            return response.ErrorResponse(res, 'Image upload failed', null, 400);
        }
        return response.Success(res, 'Image uploaded successfully', { url: req.body.image_url }, 200);
    });

/**
 * @route   PUT /api/v1/user/me
 * @desc    Update current user profile
 * @access  Private
 */
Router.put('/me',
    updateUserValidator,
    validate,
    UserController.editprofile);

/**
 * @route   DELETE /api/v1/user/me
 * @desc    Delete current user account
 * @access  Private
 */
Router.delete('/me', UserController.deleteprofile);

/**
 * @route   POST /api/v1/user/verification/submit
 * @desc    Submit identity verification documents
 * @access  Private
 */
Router.post('/verification/submit',
    uploadKycMiddleware,
    uploadVerificationToCloudinary,
    submitVerificationValidator,
    validate,
    UserController.submitVerification);

/**
 * @route   GET /api/v1/user/verification/status
 * @desc    Get current user's verification status
 * @access  Private
 */
Router.get('/verification/status', UserController.getVerificationStatus);

// ─── Recovery Points ──────────────────────────────────────────────────────────

/**
 * @route   GET /api/v1/user/me/points
 * @desc    Get current user's points balance + summary stats
 * @access  Private
 * @returns { current_balance, total_earned, total_redeemed, pending_redemptions, pending_points, pending_egp }
 */
Router.get('/me/points', UserController.getPointsSummary);

/**
 * @route   GET /api/v1/user/me/points/history
 * @desc    Get current user's recovery points transaction history (paginated)
 * @access  Private
 * @query   ?limit=30&offset=0
 */
Router.get('/me/points/history', UserController.getPointsHistory);

/**
 * @route   GET /api/v1/user/me/points/tiers
 * @desc    Get available cash redemption tiers
 * @access  Private
 * @returns { points_per_egp, wallet_providers, tiers: [{ points, cash_amount_egp, label, description }] }
 */
Router.get('/me/points/tiers', UserController.getAvailableTiers);

// ─── Wallet Cash Redemption ───────────────────────────────────────────────────

/**
 * @route   POST /api/v1/user/me/redeem
 * @desc    Submit a wallet cash redemption request
 * @access  Private
 * @body    { tier_points: 500|1000|1500|2000, wallet_provider: string, wallet_number: string }
 */
Router.post('/me/redeem',
    createRedemptionValidator,
    validate,
    UserController.redeemCash);

/**
 * @route   GET /api/v1/user/me/redemptions
 * @desc    Get current user's wallet cash redemption history (paginated)
 * @access  Private
 * @query   ?limit=30&offset=0
 */
Router.get('/me/redemptions', UserController.getRedemptionsHistory);

module.exports = Router;
