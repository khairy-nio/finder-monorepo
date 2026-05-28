const { User } = require('../models');
const Chat = require('../models/Chat.model');
const Message = require('../models/Message.model');
const { Op } = require('sequelize');

class ChatRepo {

    /**
     * Create or get existing chat between two users
     * Prevents duplicate chats by sorting user IDs
     */
    async createOrGetChat(postId, userId1, userId2) {
        try {
            // Sort user IDs to ensure consistent chat lookup
            const [user1, user2] = userId1 < userId2 ? [userId1, userId2] : [userId2, userId1];
            
            const [chat, created] = await Chat.findOrCreate({
                where: {
                    post_id: postId,
                    user_1: user1,
                    user_2: user2
                },
                defaults: {
                    post_id: postId,
                    user_1: user1,
                    user_2: user2
                }
            });
            
            return { chat, created };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get chat by ID with user details
     */
    async getChatById(chatId) {
        try {
            return await Chat.findOne({
                where: { id: chatId },
                include: [
                    {
                        model: User,
                        as: 'firstUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: User,
                        as: 'secondUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: require('../models/post.model'),
                        as: 'post',
                        attributes: ['id', 'title', 'image_url', 'status']
                    }
                ]
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Check if user is participant in chat
     */
    async isUserInChat(chatId, userId) {
        try {
            const chat = await Chat.findOne({
                where: {
                    id: chatId,
                    [Op.or]: [
                        { user_1: userId },
                        { user_2: userId }
                    ]
                }
            });
            return !!chat;
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all chats for a user with pagination
     */
    async getUserChats(userId, limit = 10, offset = 0) {
        try {
            const result = await Chat.findAndCountAll({
                where: {
                    [Op.or]: [
                        { user_1: userId },
                        { user_2: userId }
                    ]
                },
                include: [
                    {
                        model: User,
                        as: 'firstUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: User,
                        as: 'secondUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: require('../models/post.model'),
                        as: 'post',
                        attributes: ['id', 'title', 'image_url', 'status']
                    }
                ],
                limit,
                offset,
                order: [['updated_at', 'DESC']]
            });
            
            return result;
        } catch (err) {
            throw err;
        }
    }

    /**
     * Send a message in a chat — increments receiver's unread count
     */
    async sendMessage(chatId, senderId, content, clientMsgId = null) {
        const sequelize = require('../db/Sequelize');
        const transaction = await sequelize.transaction();

        try {
            // Check for idempotency: if we already received this client_msg_id, just return it
            if (clientMsgId) {
                const existingMsg = await Message.findOne({
                    where: { chat_id: chatId, client_msg_id: clientMsgId },
                    transaction
                });

                if (existingMsg) {
                    await transaction.rollback();
                    return existingMsg; // Return existing message to gracefully handle duplicates
                }
            }

            // Fetch the chat to find who is user_1 and user_2
            const chat = await Chat.findOne({ where: { id: chatId }, transaction });
            if (!chat) {
                await transaction.rollback();
                throw new Error('Chat not found');
            }

            const message = await Message.create({
                chat_id: chatId,
                sender_id: senderId,
                content,
                client_msg_id: clientMsgId
            }, { transaction });

            // Determine which unread column belongs to the receiver safely
            const isUser1 = String(chat.user_1).toLowerCase() === String(senderId).toLowerCase();
            const unreadField = isUser1 ? 'unread_user2' : 'unread_user1';

            // Atomically increment receiver unread + touch updated_at
            // Parse existing value strictly to prevent string concatenation if column is NUMERIC
            const currentUnread = parseInt(chat[unreadField] || 0, 10);
            await Chat.update(
                {
                    [unreadField]: currentUnread + 1,
                    updated_at: new Date()
                },
                { 
                    where: { id: chatId },
                    transaction 
                }
            );

            await transaction.commit();
            
            return message;
        } catch (err) {
            await transaction.rollback();
            throw err;
        }
    }

    /**
     * Mark chat as read for a specific user — resets their unread count
     */
    async markChatRead(chatId, userId) {
        try {
            const chat = await Chat.findOne({ where: { id: chatId } });
            if (!chat) return;

            const isUser1 = String(chat.user_1).toLowerCase() === String(userId).toLowerCase();
            const unreadField = isUser1 ? 'unread_user1' : 'unread_user2';

            await Chat.update(
                { [unreadField]: 0 },
                { where: { id: chatId } }
            );
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get messages for a chat with pagination
     */
    async getMessagesByChatId(chatId, limit = 50, offset = 0) {
        try {
            const result = await Message.findAndCountAll({
                where: { chat_id: chatId },
                include: [
                    {
                        model: User,
                        as: 'sender',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    }
                ],
                limit,
                offset,
                order: [['created_at', 'ASC']]
            });
            
            return result;
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get chat between two specific users
     */
    async getChatBetweenUsers(postId, userId1, userId2) {
        try {
            // Sort user IDs to ensure consistent lookup
            const [user1, user2] = userId1 < userId2 ? [userId1, userId2] : [userId2, userId1];
            
            return await Chat.findOne({
                where: {
                    post_id: postId,
                    user_1: user1,
                    user_2: user2
                },
                include: [
                    {
                        model: User,
                        as: 'firstUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: User,
                        as: 'secondUser',
                        attributes: ['id', 'name', 'email', 'profile_image_url', 'selfie_image_url']
                    },
                    {
                        model: require('../models/post.model'),
                        as: 'post',
                        attributes: ['id', 'title', 'image_url', 'status']
                    }
                ]
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Delete a chat and all its messages (cascade handled by DB)
     */
    async deleteChat(chatId) {
        try {
            return await Chat.destroy({
                where: { id: chatId }
            });
        } catch (err) {
            throw err;
        }
    }
}

module.exports = new ChatRepo();

