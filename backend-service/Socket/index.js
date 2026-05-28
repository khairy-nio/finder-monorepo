const authMiddleware = require('./Middlewares/auth.middlewares');
const onConnection = require('./connection_handler');

module.exports = (io) => {
    // Apply authentication middleware
    io.use(authMiddleware);

    // Handle connection
    io.on('connection', (socket) => {
        onConnection(io, socket);
    });
};