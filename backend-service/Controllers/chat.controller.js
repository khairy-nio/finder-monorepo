const response = require('../utils/response.util');
const ChatService = require('../services/chat.service');

class ChatController {

    /**
     * Create or get existing chat with another user
     */
    async createOrGetChat(req, res) {
        try {
            const currentUserId = req.user.id;
            const { other_user_id } = req.body;

            if (!other_user_id) {
                return response.ErrorResponse(res, 'other_user_id is required', null, 400);
            }

            const ContactRequest = require('../models/ContactRequest.model');
            const { Op } = require('sequelize');
            const hasAcceptedRequest = await ContactRequest.findOne({
                where: {
                    status: 'accepted',
                    [Op.or]: [
                        { sender_id: currentUserId, receiver_id: other_user_id },
                        { sender_id: other_user_id, receiver_id: currentUserId }
                    ]
                }
            });

            if (!hasAcceptedRequest) {
                return response.ErrorResponse(res, 'Access denied: You must have an accepted contact request to start a chat', null, 403);
            }

            const result = await ChatService.createOrGetChat(currentUserId, other_user_id);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in createOrGetChat:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get chat by ID
     */
    async getChatById(req, res) {
        try {
            const { chatId } = req.params;
            const currentUserId = req.user.id;

            // Security check: Verify user is participant
            const isParticipant = await ChatService.isUserInChat(chatId, currentUserId);
            if (!isParticipant) {
                return response.ErrorResponse(res, 'Access denied: You are not a participant in this chat', null, 403);
            }

            const result = await ChatService.getChatById(chatId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            const raw = result.data.toJSON ? result.data.toJSON() : result.data;
            const isUser1 = raw.user_1 === currentUserId;
            const otherUser = isUser1 ? raw.secondUser : raw.firstUser;
            
            const shaped = {
                id: raw.id,
                user_1: raw.user_1,
                user_2: raw.user_2,
                other_user_id: otherUser?.id || null,
                other_user_name: otherUser?.name || null,
                other_user_avatar: otherUser?.profile_image_url || otherUser?.selfie_image_url || null,
                created_at: raw.created_at,
                updated_at: raw.updated_at,
            };
            
            return response.Success(res, result.message, shaped, 200);
        } catch (error) {
            console.error('Error in getChatById:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get all chats for current user
     */
    async getUserChats(req, res) {
        try {
            const userId = req.user.id;
            const limit = parseInt(req.query.limit) || 10;
            const offset = parseInt(req.query.offset) || 0;

            const result = await ChatService.getUserChats(userId, limit, offset);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in getUserChats:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Send a message in a chat
     */
    async sendMessage(req, res) {
        try {
            const { chatId } = req.params;
            const currentUserId = req.user.id;
            const { content, client_msg_id } = req.body;

            if (!content) {
                return response.ErrorResponse(res, 'Message content is required', null, 400);
            }

            // Security check: Verify user is participant
            const isParticipant = await ChatService.isUserInChat(chatId, currentUserId);
            if (!isParticipant) {
                return response.ErrorResponse(res, 'Access denied: You are not a participant in this chat', null, 403);
            }

            const result = await ChatService.sendMessage(chatId, currentUserId, content, client_msg_id);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            // Emit socket event
            const io = req.app.get('io');
            if (io) {
                const messageData = result.data.toJSON ? result.data.toJSON() : result.data;
                const { buildEvent, normalizeMessage, normalizeConversation, normalizeUser } = require('../utils/realtime_event.util');

                // Send notification to the receiver & get chat details
                const chatData = await ChatService.getChatById(chatId);
                
                let conversationRef = null;
                let receiverId = null;

                if (chatData.success && chatData.data) {
                    const chat = chatData.data.toJSON ? chatData.data.toJSON() : chatData.data;
                    conversationRef = normalizeConversation(chat);
                    receiverId = chat.user_1 === currentUserId ? chat.user_2 : chat.user_1;
                }
                
                const eventPayload = buildEvent({
                    eventType: 'message.created',
                    actor: normalizeUser(req.user),
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
                        actor: normalizeUser(req.user),
                        conversation: conversationRef,
                        data: {
                            last_message: previewContent,
                            last_message_sender_id: currentUserId,
                            unread_increment: 1, // Only receiver actually cares, but payload can signal it
                        }
                    });

                    io.to(`user:${receiverId}`).emit('event', chatUpdatePayload);
                    
                    // Sender's update (no unread increment)
                    const senderUpdatePayload = buildEvent({
                        eventType: 'conversation.updated',
                        actor: normalizeUser(req.user),
                        conversation: conversationRef,
                        data: {
                            last_message: previewContent,
                            last_message_sender_id: currentUserId,
                            unread_increment: 0,
                        }
                    });
                    io.to(`user:${currentUserId}`).emit('event', senderUpdatePayload);

                    const NotificationService = require('../services/notification.service');
                    NotificationService.sendNotification(receiverId, 'new_message', chatId, io);
                }
            }
            
            return response.Success(res, result.message, result.data, 201);
        } catch (error) {
            console.error('Error in sendMessage:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Upload an image for a chat message
     */
    async uploadImage(req, res) {
        try {
            // uploadToCloudinary sets req.body.image_url
            if (!req.body.image_url) {
                return response.ErrorResponse(res, 'Image upload failed', null, 400);
            }
            
            return response.Success(res, 'Image uploaded successfully', { url: req.body.image_url }, 200);
        } catch (error) {
            console.error('Error in uploadImage:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get messages for a chat
     */
    async getChatMessages(req, res) {
        try {
            const { chatId } = req.params;
            const currentUserId = req.user.id;
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;

            // Security check: Verify user is participant
            const isParticipant = await ChatService.isUserInChat(chatId, currentUserId);
            if (!isParticipant) {
                return response.ErrorResponse(res, 'Access denied: You are not a participant in this chat', null, 403);
            }

            const result = await ChatService.getChatMessages(chatId, limit, offset);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in getChatMessages:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get chat between current user and another user
     */
    async getChatWithUser(req, res) {
        try {
            const currentUserId = req.user.id;
            const { otherUserId } = req.params;

            const result = await ChatService.getChatBetweenUsers(currentUserId, otherUserId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in getChatWithUser:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Delete a chat
     */
    async deleteChat(req, res) {
        try {
            const { chatId } = req.params;
            const currentUserId = req.user.id;

            // Security check: Verify user is participant
            const isParticipant = await ChatService.isUserInChat(chatId, currentUserId);
            if (!isParticipant) {
                return response.ErrorResponse(res, 'Access denied: You are not a participant in this chat', null, 403);
            }

            const result = await ChatService.deleteChat(chatId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            console.error('Error in deleteChat:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Mark all messages in a chat as read for the current user
     */
    async markAsRead(req, res) {
        try {
            const { chatId } = req.params;
            const currentUserId = req.user.id;

            const isParticipant = await ChatService.isUserInChat(chatId, currentUserId);
            if (!isParticipant) {
                return response.ErrorResponse(res, 'Access denied', null, 403);
            }

            await ChatService.markChatRead(chatId, currentUserId);

            // Notify the chat list listener that unread is now 0 for this user
            const io = req.app.get('io');
            if (io) {
                io.to(`user:${currentUserId}`).emit('chat_read', {
                    chat_id: chatId,
                    unread_count: 0
                });
            }

            return response.Success(res, 'Chat marked as read', null, 200);
        } catch (error) {
            console.error('Error in markAsRead:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new ChatController();
