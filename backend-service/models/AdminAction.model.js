const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize');

const AdminAction = sequelize.define('admin_actions', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false
    },
    admin_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'users',
            key: 'id'
        }
    },
    action_type: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    target_id: {
        type: DataTypes.UUID,
        allowNull: true
    }
}, {
    tableName: 'admin_actions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = AdminAction;
