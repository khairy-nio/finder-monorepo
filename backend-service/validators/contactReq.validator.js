const { body } = require('express-validator');

/**
 * Validator for contact request operations
 */

// Send contact request validator
exports.sendContactRequestValidator = [
    body('receiver_id')
        .notEmpty().withMessage('Receiver ID is required')
        .isUUID().withMessage('Receiver ID must be a valid UUID'),

    body('post_id')
        .notEmpty().withMessage('Post ID is required')
        .isUUID().withMessage('Post ID must be a valid UUID'),

    body('intro_message')
        .optional()
        .isString().withMessage('Intro message must be a string')
        .isLength({ max: 255 }).withMessage('Intro message cannot exceed 255 characters')
];

// Respond to contact request validator
exports.respondToRequestValidator = [
    body('status')
        .notEmpty().withMessage('Status is required')
        .isIn(['accepted', 'rejected']).withMessage('Status must be either "accepted" or "rejected"')
];
