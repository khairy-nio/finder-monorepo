const { body } = require('express-validator');

/**
 * Validator for chat operations
 */

// Create or get chat validator
exports.createChatValidator = [
    body('other_user_id')
        .notEmpty().withMessage('Other user ID is required')
        .isUUID().withMessage('Other user ID must be a valid UUID')
];

// Send message validator
exports.sendMessageValidator = [
    body('content')
        .notEmpty().withMessage('Message content is required')
        .trim()
        .isLength({ min: 1, max: 2000 }).withMessage('Message must be between 1 and 2000 characters')
        .custom((value) => {
            // Check if message is not just whitespace
            if (!value.trim()) {
                throw new Error('Message cannot be empty or just whitespace');
            }
            return true;
        })
];
