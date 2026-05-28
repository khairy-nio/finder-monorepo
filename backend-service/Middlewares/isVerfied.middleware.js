const response = require('../utils/response.util');

/**
 * Middleware to check if user is authenticated (has valid Firebase token)
 * Allows browsing but blocks unauthenticated access
 * Must be used AFTER verfyFirebaseToken middleware
 */
const requireAuthentication = async (req, res, next) => {
    try {
        // Check if user exists (auth.middleware should have set req.user)
        if (!req.user) {
            return response.ErrorResponse(res, 'Authentication required', null, 401);
        }

        next();
    } catch (error) {
        return response.ErrorResponse(res, 'Authentication Error', error.message, 500);
    }
};

/**
 * Middleware to check if user has verified identity (admin-approved)
 * Blocks actions like posting, chatting, and contact requests
 * Must be used AFTER verfyFirebaseToken middleware
 */
const requireVerification = async (req, res, next) => {
    try {
        // Check if user exists
        if (!req.user) {
            return response.ErrorResponse(res, 'Authentication required', null, 401);
        }

        // Check verification status
        const { verification_status, verified } = req.user;

        // If verification not submitted
        if (verification_status === 'not_submitted') {
            return response.ErrorResponse(
                res,
                'Identity verification required. Please submit your verification documents.',
                { verification_status: 'not_submitted' },
                403
            );
        }

        // If verification pending
        if (verification_status === 'pending') {
            return response.ErrorResponse(
                res,
                'Your verification is under review. Please wait for admin approval.',
                { verification_status: 'pending' },
                403
            );
        }

        // If verification rejected
        if (verification_status === 'rejected') {
            return response.ErrorResponse(
                res,
                'Your verification was rejected. Please resubmit with correct documents.',
                { 
                    verification_status: 'rejected',
                    notes: req.user.verification_notes 
                },
                403
            );
        }

        // If verification approved but verified flag not set
        if ((verification_status === 'approved' || verification_status === 'accepted') && !verified) {
            return response.ErrorResponse(
                res,
                'Verification inconsistency detected. Please contact support.',
                null,
                500
            );
        }

        // If verified
        if (verified && (verification_status === 'approved' || verification_status === 'accepted')) {
            return next();
        }

        // Fallback for unexpected states
        return response.ErrorResponse(
            res,
            'Verification status error',
            null,
            500
        );
    } catch (error) {
        return response.ErrorResponse(res, 'Verification Check Error', error.message, 500);
    }
};

module.exports = { requireAuthentication, requireVerification };