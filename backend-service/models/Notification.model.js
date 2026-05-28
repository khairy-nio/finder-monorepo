const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const Notification = sequelize.define('notifications', {
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
    type: {
        type: DataTypes.ENUM('match_found', 'contact_request', 'contact_accepted', 'contact_rejected', 'post_resolved', 'new_message'),
        allowNull: false
    },
    reference_id: {
        type: DataTypes.UUID,
        allowNull: true
    },
    message: {
        type: DataTypes.STRING,
        allowNull: true
    },
    is_read: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
    }
}, {
    tableName: 'notifications',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = Notification;
