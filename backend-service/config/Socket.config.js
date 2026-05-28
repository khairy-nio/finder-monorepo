module.exports = {
    // CORS settings (allow frontend to connect)
    cors: {
        origin: process.env.FRONTEND_URL || "http://localhost:3000",
        methods: ["GET", "POST"],
        credentials: true
    },

    // Connection options
    transports: ['websocket', 'polling'], // Websocket first, fallback to polling
    
    // Ping settings (check if client is alive)
    pingTimeout: 60000,  // 60 seconds
    pingInterval: 25000, // 25 seconds

    // Maximum message size
    maxHttpBufferSize: 1e6, // 1 MB (prevent huge messages)

    // Allow upgrades from polling to websocket
    allowUpgrades: true,

    // Connection state recovery (experimental)
    connectionStateRecovery: {
        maxDisconnectionDuration: 2 * 60 * 1000, // 2 minutes
    }
};