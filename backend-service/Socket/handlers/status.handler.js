module.exports = (io, socket) => {
    // When a user connects, join their own user room
    socket.join(`user:${socket.user.id}`);
    
    // Broadcast status to their connections (can be enhanced to check actual connections)
    io.emit('user_status', { userId: socket.user.id, status: 'online' });

    socket.on('disconnect', () => {
        io.emit('user_status', { userId: socket.user.id, status: 'offline' });
    });

    // Allow clients to request the current status of a specific user
    socket.on('check_user_status', ({ userId }) => {
        if (!userId) return;
        const room = io.sockets.adapter.rooms.get(`user:${userId}`);
        const isOnline = room && room.size > 0;
        socket.emit('user_status', { userId, status: isOnline ? 'online' : 'offline' });
    });
};