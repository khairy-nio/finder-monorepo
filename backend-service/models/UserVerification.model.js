const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const UserVerification = sequelize.define('user_verifications', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    id_image_url: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    phone_number: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    status: {
        type: DataTypes.ENUM('pending', 'approved', 'rejected'),
        defaultValue: 'pending',
        allowNull: false
    },
    reviewed_at: {
        type: DataTypes.DATE,
        allowNull: true
    }
}, {
    tableName: 'user_verifications',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = UserVerification;
