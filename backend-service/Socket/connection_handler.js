const chatHandler = require('./handlers/chat.handler');
const typingHandler = require('./handlers/typing.handler');
const readHandler = require('./handlers/read.handler');
const statusHandler = require('./handlers/status.handler');

const onConnection = (io, socket) => {
    console.log(`User connected: ${socket.id} (User ID: ${socket.user.id})`);
    
    // Join a personal room to receive global notifications and chat updates
    socket.join(`user:${socket.user.id}`);

    // Register all handlers
    chatHandler(io, socket);
    typingHandler(io, socket);
    readHandler(io, socket);
    statusHandler(io, socket);

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id} (User ID: ${socket.user.id})`);
    });
};

module.exports = onConnection;