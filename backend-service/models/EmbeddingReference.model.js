const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const EmbeddingReference = sequelize.define('embeddings_reference', {
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
    vector_id: {
        type: DataTypes.TEXT,
        allowNull: false
    }
}, {
    tableName: 'embeddings_reference',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = EmbeddingReference;
