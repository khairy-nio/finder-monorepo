'use strict';

const { body } = require('express-validator');
const { VALID_WALLET_PROVIDERS, VALID_TIER_POINTS, WALLET_PROVIDERS } = require('../config/rewards.config');

/**
 * Validator for POST /user/me/redeem
 * User submits a cash redemption request.
 */
exports.createRedemptionValidator = [
    body('tier_points')
        .notEmpty().withMessage('tier_points is required')
        .isInt({ min: 1 }).withMessage('tier_points must be a positive integer')
        .toInt()
        .custom((value) => {
            if (!VALID_TIER_POINTS.has(value)) {
                throw new Error(`Invalid tier. Allowed point values: ${[...VALID_TIER_POINTS].join(', ')}`);
            }
            return true;
        }),

    body('wallet_provider')
        .notEmpty().withMessage('wallet_provider is required')
        .trim()
        .custom((value) => {
            if (!VALID_WALLET_PROVIDERS.has(value)) {
                throw new Error(`Invalid wallet provider. Allowed: ${WALLET_PROVIDERS.join(', ')}`);
            }
            return true;
        }),

    body('wallet_number')
        .notEmpty().withMessage('wallet_number is required')
        .trim()
        .isLength({ min: 4, max: 20 }).withMessage('wallet_number must be between 4 and 20 characters')
        .matches(/^[0-9+\s\-]+$/).withMessage('wallet_number must contain only digits, spaces, dashes, or a leading +'),
];

/**
 * Validator for POST /admin/redemptions/:id/reject
 * Admin provides a rejection reason.
 */
exports.rejectRedemptionValidator = [
    body('reason')
        .notEmpty().withMessage('A rejection reason is required')
        .trim()
        .isLength({ min: 5, max: 500 }).withMessage('Reason must be between 5 and 500 characters'),
];
