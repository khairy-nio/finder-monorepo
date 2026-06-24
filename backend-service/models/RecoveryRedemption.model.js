const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

/**
 * WalletRedemption — Tracks a user's request to redeem points for mobile wallet cash.
 *
 * Lifecycle:
 *   pending → approved → paid      (success path)
 *   pending → rejected              (admin rejects; points are auto-refunded)
 *   pending → cancelled             (user or admin cancels)
 *
 * Points are deducted at request creation and refunded on rejection.
 * The actual cash transfer is performed manually by admins or via a future
 * wallet provider API integration.
 */
const WalletRedemption = sequelize.define('wallet_redemptions', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE'
    },
    // Points deducted from user balance at request time
    points_spent: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    // EGP cash amount to be paid out (derived from tier at creation time)
    cash_amount_egp: {
        type: DataTypes.FLOAT,
        allowNull: false
    },
    // One of: vodafone_cash | orange_cash | etisalat_cash | instapay | other_wallet
    wallet_provider: {
        type: DataTypes.STRING,
        allowNull: false
    },
    // User's mobile wallet number / payout destination
    wallet_number: {
        type: DataTypes.STRING,
        allowNull: false
    },
    // pending | approved | paid | rejected | cancelled
    status: {
        type: DataTypes.STRING,
        defaultValue: 'pending',
        allowNull: false
    },
    // Populated by admin when rejecting a request
    failure_reason: {
        type: DataTypes.TEXT,
        allowNull: true,
        defaultValue: null
    },
    // Timestamp when admin marks as paid
    paid_at: {
        type: DataTypes.DATE,
        allowNull: true,
        defaultValue: null
    },
    // Admin user ID who last processed (approved / rejected / paid) this request
    processed_by_admin_id: {
        type: DataTypes.UUID,
        allowNull: true,
        defaultValue: null,
        references: { model: 'users', key: 'id' },
        onDelete: 'SET NULL'
    }
}, {
    tableName: 'wallet_redemptions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
});

module.exports = WalletRedemption;
