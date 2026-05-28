const express = require('express');
const Router = express.Router();
const NotificationController = require('../Controllers/notification.controller');
const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const { requireAuthentication } = require('../Middlewares/isVerfied.middleware');

Router.use(verfyFirebaseToken);
Router.use(requireAuthentication);

/**
 * @route   GET /api/v1/notification
 * @desc    Get all notifications for current user
 * @access  Private
 */
Router.get('/', NotificationController.getMyNotifications);

/**
 * @route   GET /api/v1/notification/unread-count
 * @desc    Get number of unread notifications
 * @access  Private
 */
Router.get('/unread-count', NotificationController.getUnreadCount);

/**
 * @route   POST /api/v1/notification/read-all
 * @desc    Mark all notifications as read
 * @access  Private
 */
Router.post('/read-all', NotificationController.markAllAsRead);

/**
 * @route   PATCH /api/v1/notification/:id/read
 * @desc    Mark a single notification as read
 * @access  Private
 */
Router.patch('/:id/read', NotificationController.markAsRead);

module.exports = Router;
