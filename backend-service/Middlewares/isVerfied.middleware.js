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
 * Middleware to check if user has verified identity (admin-approved).
 * Valid statuses stored in DB: not_submitted | pending | approved | rejected
 * Must be used AFTER verfyFirebaseToken middleware
 */
const requireVerification = async (req, res, next) => {
    try {
        // Check if user exists
        if (!req.user) {
            return response.ErrorResponse(res, 'Authentication required', null, 401);
        }

        const { verification_status, verified } = req.user;

        // Verification not submitted yet
        if (verification_status === 'not_submitted') {
            return response.ErrorResponse(
                res,
                'Identity verification required. Please submit your verification documents.',
                { verification_status: 'not_submitted' },
                403
            );
        }

        // Waiting for admin review
        if (verification_status === 'pending') {
            return response.ErrorResponse(
                res,
                'Your verification is under review. Please wait for admin approval.',
                { verification_status: 'pending' },
                403
            );
        }

        // Admin rejected the documents
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

        // Approved but verified flag is false — DB inconsistency, should never happen
        if (verification_status === 'approved' && !verified) {
            return response.ErrorResponse(
                res,
                'Verification inconsistency detected. Please contact support.',
                null,
                500
            );
        }

        // ✅ Approved and verified — let the request through
        if (verified && verification_status === 'approved') {
            return next();
        }

        // Catch-all: unknown status value in DB
        return response.ErrorResponse(
            res,
            'Verification status unknown. Please contact support.',
            { verification_status },
            500
        );
    } catch (error) {
        return response.ErrorResponse(res, 'Verification Check Error', error.message, 500);
    }
};

module.exports = { requireAuthentication, requireVerification };