const ChatRepo = require('../Repository/chat.repo');

class ChatService {

    /**
     * Create or get existing chat between current user and another user
     */
    async createOrGetChat(postId, currentUserId, otherUserId) {
        try {
            // Validate user IDs
            if (!otherUserId || currentUserId === otherUserId) {
                return {
                    success: false,
                    message: 'Cannot create chat with yourself or invalid user'
                };
            }

            const result = await ChatRepo.createOrGetChat(postId, currentUserId, otherUserId);
            
            return {
                success: true,
                message: result.created ? 'Chat created successfully' : 'Chat already exists',
                data: result.chat,
                isNew: result.created
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get chat by ID (with security check done in controller/middleware)
     */
    async getChatById(chatId) {
        try {
            const chat = await ChatRepo.getChatById(chatId);
            
            if (!chat) {
                return {
                    success: false,
                    message: 'Chat not found'
                };
            }
            
            return {
                success: true,
                message: 'Chat retrieved successfully',
                data: chat
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all chats for a user — returns flat objects with other_user_name resolved
     */
    async getUserChats(userId, limit = 10, offset = 0) {
        try {
            const result = await ChatRepo.getUserChats(userId, limit, offset);

            // Map each chat: determine which user is "the other one"
            const mapped = await Promise.all(result.rows.map(async chat => {
                const raw = chat.toJSON ? chat.toJSON() : chat;
                const isUser1 = String(raw.user_1).toLowerCase() === String(userId).toLowerCase();
                const otherUser = isUser1 ? raw.secondUser : raw.firstUser;

                // Fetch real last message
                const lastMsgQuery = await require('../models/Message.model').findOne({
                    where: { chat_id: raw.id },
                    order: [['created_at', 'DESC']]
                });

                let lastMessageContent = null;
                if (lastMsgQuery) {
                    const isYou = String(lastMsgQuery.sender_id).toLowerCase() === String(userId).toLowerCase();
                    const prefix = isYou ? 'You: ' : `${otherUser?.name.split(' ')[0]}: `;
                    
                    if (lastMsgQuery.content.startsWith('http')) {
                        lastMessageContent = `${prefix}📷 Image`;
                    } else {
                        lastMessageContent = `${prefix}${lastMsgQuery.content}`;
                    }
                }

                return {
                    id: raw.id,
                    post: raw.post || null,
                    other_user_id: otherUser?.id || null,
                    other_user_name: otherUser?.name || 'Unknown',
                    other_user_email: otherUser?.email || null,
                    other_user_avatar: otherUser?.profile_image_url || otherUser?.selfie_image_url || null,
                    last_message: lastMessageContent,
                    updated_at: raw.updated_at || raw.created_at,
                    // Per-user unread: resolve correct column for this viewer
                    unread_count: isUser1 ? (raw.unread_user1 || 0) : (raw.unread_user2 || 0),
                    is_online: false,
                };
            }));

            return {
                success: true,
                message: 'Chats retrieved successfully',
                data: mapped,
                pagination: {
                    total: result.count,
                    limit,
                    offset,
                    hasMore: offset + limit < result.count
                }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Send a message in a chat (security check done in controller/middleware)
     */
    async sendMessage(chatId, senderId, content, clientMsgId = null) {
        try {
            // Validate content
            if (!content || content.trim().length === 0) {
                return {
                    success: false,
                    message: 'Message content cannot be empty'
                };
            }

            const message = await ChatRepo.sendMessage(chatId, senderId, content.trim(), clientMsgId);
            
            return {
                success: true,
                message: 'Message sent successfully',
                data: message
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get messages for a chat (security check done in controller/middleware)
     */
    async getChatMessages(chatId, limit = 50, offset = 0) {
        try {
            const result = await ChatRepo.getMessagesByChatId(chatId, limit, offset);
            
            return {
                success: true,
                message: 'Messages retrieved successfully',
                data: result.rows,
                pagination: {
                    total: result.count,
                    limit,
                    offset,
                    hasMore: offset + limit < result.count
                }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get chat between two users
     */
    async getChatBetweenUsers(postId, userId1, userId2) {
        try {
            const chat = await ChatRepo.getChatBetweenUsers(postId, userId1, userId2);
            
            if (!chat) {
                return {
                    success: false,
                    message: 'No chat found between these users'
                };
            }
            
            return {
                success: true,
                message: 'Chat found',
                data: chat
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Delete a chat (security check done in controller/middleware)
     */
    async deleteChat(chatId) {
        try {
            const result = await ChatRepo.deleteChat(chatId);
            
            if (result === 0) {
                return {
                    success: false,
                    message: 'Chat not found'
                };
            }
            
            return {
                success: true,
                message: 'Chat deleted successfully'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Check if user is participant in chat
     */
    async isUserInChat(chatId, userId) {
        try {
            return await ChatRepo.isUserInChat(chatId, userId);
        } catch (err) {
            throw err;
        }
    }

    /**
     * Mark all messages in a chat as read for a specific user
     */
    async markChatRead(chatId, userId) {
        try {
            await ChatRepo.markChatRead(chatId, userId);
            return { success: true };
        } catch (err) {
            throw err;
        }
    }
}

module.exports = new ChatService();
