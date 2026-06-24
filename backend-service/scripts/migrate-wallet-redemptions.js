'use strict';

/**
 * Migration: Wallet Redemptions System
 * =====================================
 * This script safely migrates the database to support the new
 * wallet cash redemption system:
 *
 *  1. Creates the new `wallet_redemptions` table
 *  2. Adds `redemption_id` column to `recovery_point_transactions`
 *  3. Renames old `recovery_redemptions` table to `recovery_redemptions_legacy`
 *     (preserves old data, does not delete it)
 *
 * Run with: node scripts/migrate-wallet-redemptions.js
 *
 * Safe to run multiple times — uses IF NOT EXISTS / IF EXISTS guards.
 */

require('dotenv').config();
require('../models/index'); // registers all models and associations

const sequelize = require('../db/Sequelize');

async function migrate() {
    const qi = sequelize.getQueryInterface();

    console.log('\n🔄 Starting wallet redemption migration...\n');

    // ── STEP 1: Create wallet_redemptions table ────────────────────────────────
    console.log('[1/3] Creating wallet_redemptions table...');
    try {
        const { DataTypes } = require('sequelize');
        await qi.createTable('wallet_redemptions', {
            id: {
                type         : DataTypes.UUID,
                defaultValue : DataTypes.UUIDV4,
                primaryKey   : true,
                allowNull    : false
            },
            user_id: {
                type      : DataTypes.UUID,
                allowNull : false,
                references: { model: 'users', key: 'id' },
                onDelete  : 'CASCADE'
            },
            points_spent: {
                type      : DataTypes.INTEGER,
                allowNull : false
            },
            cash_amount_egp: {
                type      : DataTypes.FLOAT,
                allowNull : false
            },
            wallet_provider: {
                type      : DataTypes.STRING,
                allowNull : false
            },
            wallet_number: {
                type      : DataTypes.STRING,
                allowNull : false
            },
            status: {
                type         : DataTypes.STRING,
                defaultValue : 'pending',
                allowNull    : false
            },
            failure_reason: {
                type         : DataTypes.TEXT,
                allowNull    : true,
                defaultValue : null
            },
            paid_at: {
                type         : DataTypes.DATE,
                allowNull    : true,
                defaultValue : null
            },
            processed_by_admin_id: {
                type         : DataTypes.UUID,
                allowNull    : true,
                defaultValue : null
            },
            created_at: {
                type      : DataTypes.DATE,
                allowNull : false,
                defaultValue: sequelize.literal('NOW()')
            },
            updated_at: {
                type      : DataTypes.DATE,
                allowNull : false,
                defaultValue: sequelize.literal('NOW()')
            }
        }, {
            ifNotExists: true
        });
        console.log('   ✅ wallet_redemptions table ready\n');
    } catch (err) {
        if (err.message && err.message.toLowerCase().includes('already exists')) {
            console.log('   ℹ️  wallet_redemptions already exists — skipping\n');
        } else {
            console.error('   ❌ Failed to create wallet_redemptions:', err.message);
            throw err;
        }
    }

    // ── STEP 2: Add redemption_id column to recovery_point_transactions ────────
    console.log('[2/3] Adding redemption_id column to recovery_point_transactions...');
    try {
        const { DataTypes } = require('sequelize');
        await qi.addColumn('recovery_point_transactions', 'redemption_id', {
            type         : DataTypes.UUID,
            allowNull    : true,
            defaultValue : null
        });
        console.log('   ✅ redemption_id column added\n');
    } catch (err) {
        if (err.message && (
            err.message.toLowerCase().includes('already exists') ||
            err.message.toLowerCase().includes('duplicate column')
        )) {
            console.log('   ℹ️  redemption_id column already exists — skipping\n');
        } else {
            console.error('   ❌ Failed to add redemption_id column:', err.message);
            // Non-fatal: column may not be critical for all operations
        }
    }

    // ── STEP 3: Archive old recovery_redemptions table ─────────────────────────
    console.log('[3/3] Archiving old recovery_redemptions table (renaming to _legacy)...');
    try {
        await qi.renameTable('recovery_redemptions', 'recovery_redemptions_legacy');
        console.log('   ✅ recovery_redemptions renamed to recovery_redemptions_legacy\n');
    } catch (err) {
        if (err.message && (
            err.message.toLowerCase().includes('does not exist') ||
            err.message.toLowerCase().includes('undefined table') ||
            err.message.toLowerCase().includes('no such table')
        )) {
            console.log('   ℹ️  recovery_redemptions table not found — nothing to archive\n');
        } else if (err.message && err.message.toLowerCase().includes('already exists')) {
            console.log('   ℹ️  recovery_redemptions_legacy already exists — skipping rename\n');
        } else {
            console.warn('   ⚠️  Could not rename recovery_redemptions:', err.message);
            // Non-fatal: the old table doesn't block the new system
        }
    }

    console.log('✅ Migration complete.\n');
    process.exit(0);
}

migrate().catch(err => {
    console.error('\n💥 Migration failed:', err);
    process.exit(1);
});
