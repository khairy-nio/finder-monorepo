const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const Chat = sequelize.define('chats', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    post_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'posts',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    user_1: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    user_2: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    // Per-user unread counts: incremented for receiver, reset when they open the chat
    unread_user1: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false
    },
    unread_user2: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false
    }
}, {
    tableName: 'chats',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            unique: true,
            fields: ['post_id', 'user_1', 'user_2']
        }
    ]
});

module.exports = Chat;
