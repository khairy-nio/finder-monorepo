const express = require('express');
const Router = express.Router();
const matchingController = require('../Controllers/matching.controller');
const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const { requireAuthentication,requireVerification } = require('../Middlewares/isVerfied.middleware');
const { uploadMiddleware, uploadToCloudinary } = require('../Middlewares/multer.middleware');
const { matchingValidator } = require('../validators/matching.validator');
const validate = require('../Middlewares/validation');

// Apply auth middleware to all routes
Router.use(verfyFirebaseToken);
Router.use(requireAuthentication);
// Router.use(requireVerification); // Authentication is required for all matching routes

/**
 * @route   POST /api/v1/match/find-matches
 * @desc    Find visually similar posts using AI matching
 * @access  Private (requires authentication)
 * @body    multipart/form-data - image, type, category, country, state, city, latitude, longitude
 */
Router.post('/find-matches', 
    uploadMiddleware, 
    uploadToCloudinary, 
    matchingValidator,
    validate,
    matchingController.findMatches
);

module.exports = Router;
