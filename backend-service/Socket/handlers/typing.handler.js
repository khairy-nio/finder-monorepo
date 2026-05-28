module.exports = (io, socket) => {
    socket.on('typing_start', ({ chatId }) => {
        socket.to(`chat:${chatId}`).emit('user_typing', { userId: socket.user.id, chatId });
    });

    socket.on('typing_stop', ({ chatId }) => {
        socket.to(`chat:${chatId}`).emit('user_stopped_typing', { userId: socket.user.id, chatId });
    });
};