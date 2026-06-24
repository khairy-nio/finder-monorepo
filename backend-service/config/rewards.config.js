'use strict';

/**
 * ============================================================
 *  FINDER APP — RECOVERY REWARDS BUSINESS CONSTANTS
 *  Single source of truth for all point and cash reward rules.
 *  Do NOT scatter these values across services.
 * ============================================================
 */

// ─── Point distribution per successful recovery ────────────────────────────────
// Exactly 100 points are distributed per successful recovery.
// The FINDER (person who found/returned the item) gets 70.
// The OWNER (person who lost the item and received it back) gets 30.
const FINDER_POINTS = 70;   // awarded to: found-post owner OR lost-post accepted claimant
const OWNER_POINTS  = 30;   // awarded to: lost-post owner OR found-post accepted claimant

// ─── Cash conversion rate ──────────────────────────────────────────────────────
// 10 points = 1 EGP  →  1 point = 0.10 EGP
const POINTS_PER_EGP = 10;

// ─── Allowed redemption tiers ──────────────────────────────────────────────────
// Users may ONLY redeem from these fixed tiers, not arbitrary amounts.
const REDEMPTION_TIERS = [
    { points: 500,  egp: 50  },
    { points: 1000, egp: 100 },
    { points: 1500, egp: 150 },
    { points: 2000, egp: 200 },
];

// Quick lookup Set for O(1) validation
const VALID_TIER_POINTS = new Set(REDEMPTION_TIERS.map(t => t.points));

// ─── Supported mobile wallet providers ────────────────────────────────────────
const WALLET_PROVIDERS = [
    'vodafone_cash',
    'orange_cash',
    'etisalat_cash',
    'instapay',
    'other_wallet',
];

// Quick lookup Set for O(1) validation
const VALID_WALLET_PROVIDERS = new Set(WALLET_PROVIDERS);

// ─── Transaction reason codes ─────────────────────────────────────────────────
// Used in the recovery_point_transactions.reason column.
const TRANSACTION_REASONS = {
    FINDER_REWARD      : 'successful_recovery_finder',   // +70 pts to finder
    OWNER_REWARD       : 'successful_recovery_owner',    // +30 pts to owner
    CASH_REDEMPTION    : 'cash_redemption',              // -N  pts spent for wallet payout
    CASH_REFUND        : 'cash_redemption_refund',       // +N  pts refunded on rejection
    ADMIN_ADJUSTMENT   : 'admin_points_adjustment',      // ±N  pts by admin
};

// ─── Redemption status lifecycle ──────────────────────────────────────────────
// pending → approved → paid     (success path)
// pending → rejected             (admin rejects; points refunded automatically)
// pending → cancelled            (user or admin cancels before processing)
const REDEMPTION_STATUSES = {
    PENDING   : 'pending',
    APPROVED  : 'approved',
    PAID      : 'paid',
    REJECTED  : 'rejected',
    CANCELLED : 'cancelled',
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Look up a redemption tier by its point cost.
 * @param {number} points
 * @returns {{ points: number, egp: number } | null}
 */
function getTierByPoints(points) {
    return REDEMPTION_TIERS.find(t => t.points === Number(points)) ?? null;
}

/**
 * Mask a wallet phone number for safe display.
 * Keeps first 3 and last 2 digits visible.
 * Example: "01012345678" → "010*****78"
 * @param {string} walletNumber
 * @returns {string}
 */
function maskWalletNumber(walletNumber) {
    if (!walletNumber || walletNumber.length < 6) return '***';
    const str = String(walletNumber);
    return str.slice(0, 3) + '*'.repeat(str.length - 5) + str.slice(-2);
}

module.exports = {
    FINDER_POINTS,
    OWNER_POINTS,
    POINTS_PER_EGP,
    REDEMPTION_TIERS,
    VALID_TIER_POINTS,
    WALLET_PROVIDERS,
    VALID_WALLET_PROVIDERS,
    TRANSACTION_REASONS,
    REDEMPTION_STATUSES,
    getTierByPoints,
    maskWalletNumber,
};
