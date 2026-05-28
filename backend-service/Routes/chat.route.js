const express = require('express');
const Router = express.Router();
const chatController = require('../Controllers/chat.controller');
const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const { requireVerification, requireAuthentication } = require('../Middlewares/isVerfied.middleware');const { requireActiveUser } = require('../Middlewares/moderation.middleware');const { verifyChatParticipant } = require('../Middlewares/chat.middleware');
const { createChatValidator, sendMessageValidator } = require('../validators/chat.validator');
const validate = require('../Middlewares/validation');

// All chat operations require verified identity
Router.use(verfyFirebaseToken);
Router.use(requireAuthentication);
Router.use(requireVerification);

/**
 * @route   POST /api/v1/chat/create
 * @desc    Create or get existing chat with another user
 * @access  Private (requires verified identity)
 * @body    { other_user_id }
 */
Router.post('/create',
    createChatValidator,
    validate,
    chatController.createOrGetChat);

/**
 * @route   GET /api/v1/chat/my-chats
 * @desc    Get all chats for current user
 * @access  Private (requires verified identity)
 * @query   ?limit=10&offset=0
 */
Router.get('/my-chats', chatController.getUserChats);

/**
 * @route   GET /api/v1/chat/:chatId
 * @desc    Get chat details by ID
 * @access  Private (requires verified identity, participant check)
 */
Router.get('/:chatId', verifyChatParticipant, chatController.getChatById);

/**
 * @route   GET /api/v1/chat/:chatId/messages
 * @desc    Get all messages in a chat
 * @access  Private (requires verified identity, participant check)
 * @query   ?limit=50&offset=0
 */
Router.get('/:chatId/messages', verifyChatParticipant, chatController.getChatMessages);

/**
 * @route   POST /api/v1/chat/:chatId/send
 * @desc    Send a message in a chat
 * @access  Private (requires verified identity, participant check)
 * @body    { content }
 */
Router.post('/:chatId/send',
    requireActiveUser,
    verifyChatParticipant,
    sendMessageValidator,
    validate,
    chatController.sendMessage);

/**
 * @route   POST /api/v1/chat/upload-image
 * @desc    Upload an image for chat
 * @access  Private (requires verified identity)
 */
const { uploadMiddleware, uploadToCloudinary } = require('../Middlewares/multer.middleware');
Router.post('/upload-image',
    uploadMiddleware,
    uploadToCloudinary,
    chatController.uploadImage);

/**
 * @route   GET /api/v1/chat/with/:otherUserId
 * @desc    Get chat between current user and another user
 * @access  Private (requires verified identity)
 */
Router.get('/with/:otherUserId', chatController.getChatWithUser);

/**
 * @route   DELETE /api/v1/chat/:chatId
 * @desc    Delete a chat
 * @access  Private (requires verified identity, participant check)
 */
Router.delete('/:chatId', verifyChatParticipant, chatController.deleteChat);

/**
 * @route   POST /api/v1/chat/:chatId/read
 * @desc    Mark chat as read for current user (resets their unread count)
 * @access  Private (requires verified identity, participant check)
 */
Router.post('/:chatId/read', verifyChatParticipant, chatController.markAsRead);

module.exports = Router;
