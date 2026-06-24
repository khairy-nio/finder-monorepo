const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

/**
 * RecoveryPointTransaction — Ledger for all point movements.
 *
 * Reason codes (see config/rewards.config.js TRANSACTION_REASONS):
 *   successful_recovery_finder  — +70 pts awarded to the finder on post resolution
 *   successful_recovery_owner   — +30 pts awarded to the owner on post resolution
 *   cash_redemption             — negative pts deducted when user requests wallet payout
 *   cash_redemption_refund      — positive pts restored when admin rejects a payout request
 *   admin_points_adjustment     — manual ± adjustment by an admin
 */
const RecoveryPointTransaction = sequelize.define('recovery_point_transactions', {
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
    // NULL for redemption/admin transactions; set for recovery award transactions
    post_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: 'posts', key: 'id' },
        onDelete: 'SET NULL'
    },
    // Positive = earned, Negative = spent
    points: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    // See TRANSACTION_REASONS in config/rewards.config.js
    reason: {
        type: DataTypes.STRING,
        allowNull: false
    },
    // Optional link back to a WalletRedemption record for cash_redemption / cash_redemption_refund
    redemption_id: {
        type: DataTypes.UUID,
        allowNull: true,
        defaultValue: null
    }
}, {
    tableName: 'recovery_point_transactions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false   // ledger rows are immutable; no updates allowed
});

module.exports = RecoveryPointTransaction;
