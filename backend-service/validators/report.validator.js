const { body } = require('express-validator');

const VALID_REASONS = {
    user: [
        'Scam or fraudulent behavior',
        'Fake ownership claim',
        'Suspicious activity',
        'Harassment or abusive behavior',
        'Spam requests/messages',
        'Attempted theft',
        'Inappropriate communication',
        'Impersonation',
        'Asking for payment suspiciously',
        'Refusing verification process',
        'Other'
    ],
    post: [
        'Fake lost/found item',
        'Duplicate listing',
        'Incorrect category',
        'Misleading information',
        'Suspicious ownership claim',
        'Inappropriate images',
        'Spam post',
        'Item already returned',
        'Fraudulent reward claim',
        'Other'
    ],
    message: [
        'Harassment',
        'Spam',
        'Scam attempt',
        'Threatening behavior',
        'Inappropriate content',
        'Fake ownership negotiation',
        'Payment scam attempt',
        'Other'
    ],
    chat: [
        'Harassment',
        'Spam',
        'Scam attempt',
        'Threatening behavior',
        'Inappropriate content',
        'Fake ownership negotiation',
        'Payment scam attempt',
        'Other'
    ],
    general_support: [
        'App bug',
        'Notification issue',
        'Chat issue',
        'Verification issue',
        'Report system issue',
        'Performance issue',
        'Account issue',
        'UI problem',
        'Other'
    ]
};

const createReportValidator = [
    body('reportType')
        .notEmpty().withMessage('Report type is required')
        .isIn(['user', 'post', 'message', 'chat', 'general_support']).withMessage('Invalid report type'),
    
    body('reported_user_id')
        .if(body('reportType').equals('user'))
        .notEmpty().withMessage('Reported user ID is required for user reports')
        .isUUID(4).withMessage('Reported user ID must be a valid UUID'),
        
    body('reported_post_id')
        .if(body('reportType').equals('post'))
        .notEmpty().withMessage('Reported post ID is required for post reports')
        .isUUID(4).withMessage('Reported post ID must be a valid UUID'),

    body('reported_message_id')
        .if(body('reportType').equals('message'))
        .notEmpty().withMessage('Reported message ID is required for message reports')
        .isUUID(4).withMessage('Reported message ID must be a valid UUID'),

    body('reported_chat_id')
        .if(body('reportType').equals('chat'))
        .notEmpty().withMessage('Reported chat ID is required for chat reports')
        .isUUID(4).withMessage('Reported chat ID must be a valid UUID'),
    body('reason')
        .notEmpty().withMessage('Reason is required')
        .custom((value, { req }) => {
            const reportType = req.body.reportType;
            if (!VALID_REASONS[reportType]) {
                throw new Error('Invalid report type');
            }
            if (!VALID_REASONS[reportType].includes(value)) {
                throw new Error(`Invalid reason for report type ${reportType}`);
            }
            return true;
        }),
    body('note')
        .optional()
        .isString().withMessage('Note must be a string')
        .isLength({ max: 2000 }).withMessage('Note cannot exceed 2000 characters')
];

const updateReportStatusValidator = [
    body('status')
        .optional()
        .isIn(['pending', 'resolved']).withMessage('Status must be pending or resolved'),
    body('reason')
        .optional()
        .isString().withMessage('Reason must be a string')
        .isLength({ min: 2, max: 255 }).withMessage('Reason must be between 2 and 255 characters'),
    body('note')
        .optional()
        .isString().withMessage('Note must be a string')
        .isLength({ max: 2000 }).withMessage('Note cannot exceed 2000 characters')
];

module.exports = {
    createReportValidator,
    updateReportStatusValidator
};
