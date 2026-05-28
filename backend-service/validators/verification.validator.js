const { body } = require('express-validator');

/**
 * Validator for user verification operations
 */

// Submit verification validator
exports.submitVerificationValidator = [
    body('national_id')
        .notEmpty().withMessage('National ID is required')
        .trim()
        .isLength({ min: 5, max: 50 }).withMessage('National ID must be between 5 and 50 characters'),

    body('phone_number')
        .notEmpty().withMessage('Phone number is required')
        .trim()
        .matches(/^\+?[1-9]\d{1,14}$/).withMessage('Phone number must be in E.164 format (e.g., +1234567890)'),

    body('id_image_url')
        .notEmpty().withMessage('ID image URL is required')
        .isURL().withMessage('ID image URL must be a valid URL'),

    body('selfie_image_url')
        .optional()
        .isURL().withMessage('Selfie image URL must be a valid URL'),

    body('verification_location')
        .optional()
        .trim()
];

// Approve/Reject verification validator
exports.verificationResponseValidator = [
    body('notes')
        .optional()
        .trim()
        .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters')
];
