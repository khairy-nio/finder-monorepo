const { DataTypes } = require('sequelize');
const sequelize = require('../db/Sequelize'); // Adjust path to your DB connection
const User =sequelize.define('users',{
    id:{
        type:DataTypes.UUID,
        defaultValue:DataTypes.UUIDV4,
        primaryKey:true,
        allowNull:false,
        unique:true
    },
    firebase_uid:{
        type:DataTypes.STRING,
        allowNull:false,
        unique:true
    },
    name:{
        type:DataTypes.STRING,
        allowNull:false
    }, 
    email:{
        type:DataTypes.STRING,
        allowNull:false,
        unique:true
    },
    role:{
        type:DataTypes.ENUM('user','admin'),
        defaultValue:'user',
        allowNull:false
    },
    status: {
        type: DataTypes.ENUM('active', 'suspended', 'banned'),
        defaultValue: 'active',
        allowNull: false
    },
    verified:{
        type:DataTypes.BOOLEAN,
        defaultValue:false,
        allowNull:false
    },
    trust_score:{
        type:DataTypes.FLOAT,
        defaultValue:0.0,
        allowNull:false
    },
    bio:{
        type:DataTypes.TEXT,
        allowNull:true
    },
    recovery_points:{
        type:DataTypes.INTEGER,
        defaultValue:0,
        allowNull:false
    },
    national_id: {

        type: DataTypes.STRING,
        allowNull: true
    },
    phone_number: {
        type: DataTypes.STRING,
        allowNull: true
    },
    country: {
        type: DataTypes.STRING,
        allowNull: true
    },
    state: {
        type: DataTypes.STRING,
        allowNull: true
    },
    city: {
        type: DataTypes.STRING,
        allowNull: true
    },
    area: {
        type: DataTypes.STRING,
        allowNull: true
    },
    profile_image_url: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    selfie_image_url: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    id_image_url: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    verification_location: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    verification_status: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: 'not_submitted'  // not_submitted, pending, approved, rejected
    },
    verification_submitted_at: {
        type: DataTypes.DATE,
        allowNull: true
    },
    verification_reviewed_at: {
        type: DataTypes.DATE,
        allowNull: true
    },
    verification_notes: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    moderation_reason: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    moderated_at: {
        type: DataTypes.DATE,
        allowNull: true
    }
},
{
    tableName: 'users',
    timestamps: true,      // Enables automatic timestamps
    createdAt: 'created_at', // Maps Sequelize 'createdAt' -> DB 'created_at'
    updatedAt: false,
    }
  

);

module.exports=User;