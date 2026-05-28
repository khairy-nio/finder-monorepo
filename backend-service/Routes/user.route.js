const authController = require('../Controllers/auth.controller');
const UserController = require('../Controllers/User.controller');
const response = require('../utils/response.util');
const { verfyFirebaseToken, verfyFirebaseTokenLite } = require('../Middlewares/auth.middleware');
const { requireAuthentication } = require('../Middlewares/isVerfied.middleware');
const { createUserValidator, updateUserValidator } = require('../validators/user.validator');
const { submitVerificationValidator } = require('../validators/verification.validator');
const { uploadKycMiddleware, uploadVerificationToCloudinary } = require('../Middlewares/multer.middleware');
const validate = require('../Middlewares/validation');
const express =require('express');
const Router = express.Router();

/**
 * @route   POST /api/v1/user/login
 * @desc    Login or register user after Firebase authentication
 * @access  Public (requires Firebase token)
 * @body    { name, email }
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
 * @access  Private (requires authentication)
 */
Router.get('/me',      
       UserController.getprofile);

/**
 * @route   POST /api/v1/user/upload-image
 * @desc    Upload an image (e.g. for profile or selfie)
 * @access  Private (requires authentication)
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
 * @access  Private (requires authentication)
 * @body    { name, phone }
 */
Router.put('/me',
       updateUserValidator,
       validate,
       UserController.editprofile);

/**
 * @route   DELETE /api/v1/user/me
 * @desc    Delete current user account
 * @access  Private (requires authentication)
 */
Router.delete('/me',
       UserController.deleteprofile);

/**
 * @route   POST /api/v1/user/verification/submit
 * @desc    Submit identity verification documents
 * @access  Private (requires authentication)
 * @body    { national_id, phone_number, id_image_url }
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
 * @access  Private (requires authentication)
 */
Router.get('/verification/status', UserController.getVerificationStatus);

/**
 * @route   GET /api/v1/user/me/points/history
 * @desc    Get current user's recovery points transaction history
 * @access  Private (requires authentication)
 */
Router.get('/me/points/history', UserController.getPointsHistory);

/**
 * @route   GET /api/v1/user/me/redemptions
 * @desc    Get current user's redeemed rewards history
 * @access  Private (requires authentication)
 */
Router.get('/me/redemptions', UserController.getRedemptionsHistory);

/**
 * @route   POST /api/v1/user/me/redeem
 * @desc    Redeem a catalog reward using recovery points
 * @access  Private (requires authentication)
 */
Router.post('/me/redeem', UserController.redeemReward);

module.exports=Router;

