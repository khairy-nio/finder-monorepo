const ChatService = require('../services/chat.service');
const response = require('../utils/response.util');

/**
 * Middleware to verify user is participant in chat
 * Must be used after verfyFirebaseToken and requireVerification
 */
async function verifyChatParticipant(req, res, next) {
    try {
        const userId = req.user.id;
        const chatId = req.params.chatId;

        if (!chatId) {
            return response.ErrorResponse(res, 'Chat ID is required', null, 400);
        }

        const isParticipant = await ChatService.isUserInChat(chatId, userId);
        
        if (!isParticipant) {
            return response.ErrorResponse(res, 'Access denied: You are not a participant in this chat', null, 403);
        }

        next();
    } catch (error) {
        console.error('Chat participant verification error:', error);
        return response.ErrorResponse(res, 'Server Error', error.message, 500);
    }
}

module.exports = { verifyChatParticipant };
