const NotificationRepo = require('../Repository/notification.repo');

class NotificationService {
    async sendNotification(userId, type, referenceId = null, io = null) {
        try {
            const notification = await NotificationRepo.createNotification(userId, type, referenceId);
            if (io) {
                const notifData = notification.toJSON ? notification.toJSON() : notification;
                io.to(`user:${userId}`).emit('new_notification', notifData);
            }
            return { success: true, data: notification };
        } catch (err) {
            console.error('Failed to send notification:', err);
            return { success: false, message: 'Failed to send notification' };
        }
    }

    async getUserNotifications(userId, limit = 50, offset = 0) {
        try {
            const result = await NotificationRepo.getUserNotifications(userId, limit, offset);
            return {
                success: true,
                message: 'Notifications retrieved successfully',
                data: result.rows,
                pagination: { total: result.count, limit, offset, hasMore: offset + limit < result.count },
            };
        } catch (err) { throw err; }
    }

    async markAsRead(notificationId, userId) {
        try {
            const updated = await NotificationRepo.markAsRead(notificationId, userId);
            if (updated === 0) return { success: false, message: 'Notification not found' };
            return { success: true, message: 'Marked as read' };
        } catch (err) { throw err; }
    }

    async markAllAsRead(userId) {
        try {
            await NotificationRepo.markAllAsRead(userId);
            return { success: true, message: 'All notifications marked as read' };
        } catch (err) { throw err; }
    }

    async getUnreadCount(userId) {
        try {
            const count = await NotificationRepo.getUnreadCount(userId);
            return { success: true, data: { count } };
        } catch (err) { throw err; }
    }
}

module.exports = new NotificationService();
