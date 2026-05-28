const chatService = require('../../services/chat.service');
const { buildEvent, normalizeMessage, normalizeConversation, normalizeUser } = require('../../utils/realtime_event.util');

module.exports = (io, socket) => {
    socket.on('join_chat', async ({ chatId }) => {
        try {
            const isParticipant = await chatService.isUserInChat(chatId, socket.user.id);
            if (!isParticipant) {
                return socket.emit('error', { message: 'Not authorized to join this chat' });
            }
            socket.join(`conversation:${chatId}`);
        } catch (error) {
            socket.emit('error', { message: error.message });
        }
    });

    socket.on('send_message', async ({ chatId, content, client_msg_id }) => {
        try {
            const isParticipant = await chatService.isUserInChat(chatId, socket.user.id);
            if (!isParticipant) {
                return socket.emit('error', { message: 'Not authorized to send messages in this chat' });
            }

            const result = await chatService.sendMessage(chatId, socket.user.id, content, client_msg_id);
            if (result.success) {
                const chatData = await chatService.getChatById(chatId);
                let conversationRef = null;
                let receiverId = null;

                if (chatData.success && chatData.data) {
                    const chat = chatData.data.toJSON ? chatData.data.toJSON() : chatData.data;
                    conversationRef = normalizeConversation(chat);
                    receiverId = chat.user_1 === socket.user.id ? chat.user_2 : chat.user_1;
                }

                const messageData = result.data.toJSON ? result.data.toJSON() : result.data;
                const eventPayload = buildEvent({
                    eventType: 'message.created',
                    actor: normalizeUser(socket.user),
                    conversation: conversationRef,
                    data: { message: normalizeMessage(messageData) },
                    dedupeKey: client_msg_id
                });
                
                io.to(`conversation:${chatId}`).emit('event', eventPayload);

                if (chatData.success && chatData.data) {
                    let previewContent = messageData.content;
                    if (previewContent.startsWith('http')) {
                        previewContent = '📷 Image';
                    }

                    const chatUpdatePayload = buildEvent({
                        eventType: 'conversation.updated',
                        actor: normalizeUser(socket.user),
                        conversation: conversationRef,
                        data: {
                            last_message: previewContent,
                            last_message_sender_id: socket.user.id,
                            unread_increment: 1
                        }
                    });

                    io.to(`user:${receiverId}`).emit('event', chatUpdatePayload);
                    
                    const senderUpdatePayload = buildEvent({
                        eventType: 'conversation.updated',
                        actor: normalizeUser(socket.user),
                        conversation: conversationRef,
                        data: {
                            last_message: previewContent,
                            last_message_sender_id: socket.user.id,
                            unread_increment: 0
                        }
                    });
                    
                    io.to(`user:${socket.user.id}`).emit('event', senderUpdatePayload);

                    const NotificationService = require('../../services/notification.service');
                    NotificationService.sendNotification(receiverId, 'new_message', chatId, io);
                }

            } else {
                socket.emit('error', { message: result.message });
            }
        } catch (error) {
            socket.emit('error', { message: error.message });
        }
    });

    socket.on('leave_chat', ({ chatId }) => {
        socket.leave(`conversation:${chatId}`);
    });
};