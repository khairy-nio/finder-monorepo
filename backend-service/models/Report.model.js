const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const Report = sequelize.define('reports', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    reportType: {
        type: DataTypes.ENUM('user', 'post', 'message', 'chat', 'general_support'),
        allowNull: false
    },
    reporter_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reported_user_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reported_post_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'posts',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reported_message_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'messages',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reported_chat_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'chats',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    reason: {
        type: DataTypes.STRING,
        allowNull: false
    },
    note: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    status: {
        type: DataTypes.ENUM('pending', 'resolved'),
        defaultValue: 'pending',
        allowNull: false
    }
}, {
    tableName: 'reports',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = Report;
