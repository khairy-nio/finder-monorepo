'use strict';
require('dotenv').config(); // Must be first — loads env vars before any config module runs

console.log('🔥 BOOT START');

const express = require('express');
const http = require('node:http');
const cors = require('cors');
const logger = require('morgan');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 3500;

// ─── CORS ─────────────────────────────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGINS || process.env.FRONTEND_URL || '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
const allowAllOrigins =
    allowedOrigins.length === 0 && process.env.NODE_ENV !== 'production';

app.use(cors({
    origin: (origin, callback) => {
        if (allowAllOrigins || !origin) return callback(null, true);
        if (allowedOrigins.includes(origin)) return callback(null, true);
        return callback(new Error('Not allowed by CORS'));
    },
    credentials: true
}));

// ─── Core middleware ───────────────────────────────────────────────────────────
app.use(express.json());
app.use(logger('dev'));

// ─── Socket.io ────────────────────────────────────────────────────────────────
const io = new Server(server, {
    cors: {
        origin: allowAllOrigins ? true : allowedOrigins,
        credentials: true
    }
});
app.set('io', io);

// ─── Base routes (always available, even if DB is down) ───────────────────────
app.get('/', (_req, res) => res.send('Welcome to Finder App Backend'));
app.get('/health', (_req, res) =>
    res.status(200).json({ status: 'ok', service: 'finder-backend' })
);

// ─── Global error handler ─────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
    console.error('🔥 Backend Error:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// ─── Safety net for untracked async failures ──────────────────────────────────
process.on('unhandledRejection', (reason) => {
    console.error('🚨 Unhandled Promise Rejection:', reason);
});

// ─── Startup ──────────────────────────────────────────────────────────────────
async function startServer() {
    try {
        // Step 1 — register all Sequelize models and their associations
        console.log('[1/4] Loading models…');
        require('./models/index');
        console.log('      ✅ Models loaded');

        // Step 2 — attach Socket.io event handlers
        console.log('[2/4] Initialising Socket.io…');
        require('./Socket/index')(io);
        console.log('      ✅ Socket.io ready');

        // Step 3 — mount all API routes
        console.log('[3/4] Mounting routes…');
        const routes = require('./Routes/app.route');
        app.use('/api/v1', routes);
        console.log('      ✅ Routes mounted');

        // Step 4 — sync DB schema; a failure here must NOT prevent the server
        // from starting — controllers that need the DB will fail at request time
        // with a proper error, rather than the whole process silently dying.
        console.log('[4/4] Syncing database…');
        const sequelize = require('./db/Sequelize');
        try {
            await sequelize.sync();
            console.log('      ✅ Database synced');
        } catch (dbErr) {
            console.error('      ⚠️  DB sync failed (server still starting):', dbErr.message);
        }

        // Always reach listen — this is the guarantee
        server.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.error(`💥 Port ${port} is already in use. Kill the process holding it and retry.`);
            } else {
                console.error('💥 Server error:', err);
            }
            process.exit(1);
        });

        server.listen(port, '0.0.0.0', () => {
            console.log(`\n🚀 Server running on port ${port}`);
        });

    } catch (bootErr) {
        console.error('💥 BOOT FAILED:', bootErr);
        process.exit(1);
    }
}

startServer();
