const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

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
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    post_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'posts',
            key: 'id'
        },
        onDelete: 'SET NULL'
    },
    points: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    reason: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    tableName: 'recovery_point_transactions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = RecoveryPointTransaction;
