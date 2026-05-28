const { body } = require('express-validator');

/**
 * Validator for matching/find-matches endpoint
 * Validates image upload and location data for AI-powered visual matching
 */
exports.matchingValidator = [
    // Post Type - required
    body('type')
        .notEmpty().withMessage('Type is required')
        .isIn(['lost', 'found']).withMessage('Type must be either "lost" or "found"'),

    // Category - optional but recommended
    body('category')
        .optional()
        .isString().withMessage('Category must be a string')
        .trim()
        .isLength({ min: 2, max: 50 }).withMessage('Category must be between 2 and 50 characters'),

    // Location: Country - required
    body('country')
        .notEmpty().withMessage('Country is required for location-based matching')
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('Country name must be between 2 and 100 characters'),

    // Location: State - optional
    body('state')
        .optional()
        .trim()
        .isLength({ max: 100 }).withMessage('State name cannot exceed 100 characters'),

    // Location: City - required for matching algorithm
    body('city')
        .notEmpty().withMessage('City is required for location-based matching')
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('City name must be between 2 and 100 characters'),

    // Coordinates: Latitude - optional but recommended for 40km radius filtering
    body('latitude')
        .optional()
        .isFloat({ min: -90, max: 90 }).withMessage('Latitude must be between -90 and 90'),

    // Coordinates: Longitude - optional but recommended for 40km radius filtering
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
