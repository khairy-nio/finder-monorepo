const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize'); 

const Post = sequelize.define('posts', {
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
    post_type: {
        type: DataTypes.ENUM('lost', 'found'),
        allowNull: false
    },
    title: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true
    },  
    category: {
        type: DataTypes.TEXT,
        allowNull: true
    },
  
    country:{
        type: DataTypes.STRING,
        allowNull: false
    },
    state:{
        type: DataTypes.STRING,
        allowNull: true
    },
    city:{
        type: DataTypes.STRING,
        allowNull: true
    },
    area:{
        type: DataTypes.STRING,
        allowNull: true
    },
        latitude: {
        type: DataTypes.FLOAT,
        allowNull: true
    },
    longitude: {
        type: DataTypes.FLOAT,
        allowNull: true
    },
    image_url: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    vector_id: {
        type: DataTypes.STRING,
        allowNull: true
    },
    status: {
        type: DataTypes.ENUM('active', 'matched', 'closed', 'resolved'),
        defaultValue: 'active',
        allowNull: false
    },
    moderation_status: {
        type: DataTypes.ENUM('visible', 'hidden', 'removed'),
        defaultValue: 'visible',
        allowNull: false
    },
    // Verification questions set by the post owner for non-matched claimants.
    // Stored as: [{ id: number, question: string }]
    // NULL = no questions configured (old posts + new posts without questions)
    // NEVER exposed in public feed DTOs.
    verification_questions: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: null
    }
}, {
    tableName: 'posts',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = Post;