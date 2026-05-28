module.exports = (io, socket) => {
    socket.on('message_read', ({ messageId, chatId }) => {
        socket.to(`chat:${chatId}`).emit('message_read', { messageId, chatId, userId: socket.user.id });
    });
};