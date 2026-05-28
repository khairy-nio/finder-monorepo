const NotificationService = require('../services/notification.service');
const response = require('../utils/response.util');

class NotificationController {
    async getMyNotifications(req, res) {
        try {
            const userId = req.user.id;
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;
            const result = await NotificationService.getUserNotifications(userId, limit, offset);
            return response.Success(res, result.message, result.data, 200, result.pagination);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async markAsRead(req, res) {
        try {
            const userId = req.user.id;
            const { id } = req.params;
            const result = await NotificationService.markAsRead(id, userId);
            if (!result.success) return response.ErrorResponse(res, result.message, null, 404);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async markAllAsRead(req, res) {
        try {
            const userId = req.user.id;
            const result = await NotificationService.markAllAsRead(userId);
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    async getUnreadCount(req, res) {
        try {
            const userId = req.user.id;
            const result = await NotificationService.getUnreadCount(userId);
            return response.Success(res, 'Unread count', result.data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new NotificationController();
