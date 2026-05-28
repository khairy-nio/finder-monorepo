const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const RecoveryRedemption = sequelize.define('recovery_redemptions', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reward_id: {
        type: DataTypes.STRING,
        allowNull: false
    },
    reward_title: {
        type: DataTypes.STRING,
        allowNull: false
    },
    points_spent: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    status: {
        type: DataTypes.STRING,
        defaultValue: 'pending',
        allowNull: false
    }
}, {
    tableName: 'recovery_redemptions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = RecoveryRedemption;
