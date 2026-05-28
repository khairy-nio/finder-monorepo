const { body } = require('express-validator');

exports.createPostValidator = [
    // Title
    body('title')
        .notEmpty().withMessage('Title is required')
        .trim()
        .isLength({ min: 3, max: 200 }).withMessage('Title must be between 3 and 200 characters'),

    // Post Type
    body('post_type')
        .notEmpty().withMessage('Post type is required')
        .isIn(['lost', 'found']).withMessage('Post type must be either "lost" or "found"'),

    // Category - optional
    body('category')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 }).withMessage('Category must be between 2 and 50 characters'),

    // Description - optional; max 140 chars encourages safe, concise descriptions
    body('description')
        .optional()
        .trim()
        .isLength({ max: 140 }).withMessage('Description cannot exceed 140 characters. Keep it general to protect privacy.'),

    // Location Fields
    body('country')
        .notEmpty().withMessage('Country is required')
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('Country must be between 2 and 100 characters'),
    
    body('state')
        .optional()
        .trim()
        .isLength({ max: 100 }).withMessage('State cannot exceed 100 characters'),
    
    body('city')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('City must be between 2 and 100 characters'),

    body('area')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('Area must be between 2 and 100 characters'),

    // Coordinates (Optional but recommended)
    body('latitude')
        .optional()
        .isFloat({ min: -90, max: 90 }).withMessage('Latitude must be between -90 and 90'),
    
    body('longitude')
        .optional()
        .isFloat({ min: -180, max: 180 }).withMessage('Longitude must be between -180 and 180'),

    // Custom validation: If latitude is provided, longitude must also be provided
    body('longitude').custom((value, { req }) => {
        if (req.body.latitude && !value) {
            throw new Error('Longitude is required when latitude is provided');
        }
        return true;
    }),

    body('latitude').custom((value, { req }) => {
        if (req.body.longitude && !value) {
            throw new Error('Latitude is required when longitude is provided');
        }
        return true;
    })
];

exports.updatePostValidator = [
    body('type')
        .optional()
        .isIn(['lost', 'found']).withMessage('Post type must be either "lost" or "found"'),
    
    body('category')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 }).withMessage('Category must be between 2 and 50 characters'),
    
    body('description')
        .optional()
        .trim()
        .isLength({ max: 140 }).withMessage('Description cannot exceed 140 characters. Keep it general to protect privacy.'),
    
    body('status')
        .optional()
        .isIn(['active', 'matched', 'closed', 'resolved']).withMessage('Invalid status')
];
