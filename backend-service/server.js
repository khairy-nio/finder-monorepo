const express = require('express');
const logger = require('morgan');
const cors = require('cors');
const app = express();
require('dotenv').config();
const http = require('node:http');
require('./loaders/sys_req');
const routes = require('./Routes/app.route');
const server = http.createServer(app);
const port = process.env.PORT || 3500;
const { Server } = require('socket.io');
const allowedOrigins = (process.env.CORS_ORIGINS || process.env.FRONTEND_URL || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
const allowAllOrigins = allowedOrigins.length === 0 && process.env.NODE_ENV !== 'production';

const corsOptions = {
    origin: (origin, callback) => {
        if (allowAllOrigins || !origin) {
            return callback(null, true);
        }

        if (allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        return callback(new Error('Not allowed by CORS'));
    },
    credentials: true
};

const io = new Server(server, {
    cors: {
        origin: allowAllOrigins ? true : allowedOrigins,
        credentials: true
    }
});

// Make io accessible to controllers
app.set('io', io);

// Initialize Socket.io logic
require('./Socket/index')(io);

app.use(cors(corsOptions));
app.use(express.json());
app.use(logger('dev'))
app.get('/',(req,res)=>{
    res.send('Welcome to Finder App Backend');
});
app.use('/api/v1', routes);

// Global Error Handler to log errors explicitly
app.use((err, req, res, next) => {
    console.error('🔥 Backend Error Detected:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});

const sequelize = require('./db/Sequelize');

// Sync database models before starting the server
sequelize.sync()
    .then(() => {
        console.log('📦 Database models synced successfully');
        server.listen(port, '0.0.0.0', () => {
            console.log(`backend running on port ${port}`);
        });
    })
    .catch((err) => {
        console.error('❌ Failed to sync database models:', err);
    });

