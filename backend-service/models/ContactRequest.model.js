const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const ContactRequest = sequelize.define('contact_requests', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    sender_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    receiver_id: {
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
        allowNull: false,
        references: {
            model: 'posts',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    status: {
        type: DataTypes.ENUM('pending', 'accepted', 'rejected'),
        defaultValue: 'pending',
        allowNull: false
    },
    intro_message: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    // Claimant's answers to the owner's verification questions.
    // Stored as: [{ questionId: number, answer: string }]
    // NULL = old request, or post had no verification questions set.
    verification_answers: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: null
    }
}, {
    tableName: 'contact_requests',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = ContactRequest;
