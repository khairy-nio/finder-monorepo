const Notification = require('../models/Notification.model');

class NotificationRepo {
    /**
     * Get all notifications for a user (newest first)
     */
    async getUserNotifications(userId, limit = 50, offset = 0) {
        try {
            return await Notification.findAndCountAll({
                where: { user_id: userId },
                order: [['created_at', 'DESC']],
                limit,
                offset,
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Mark a single notification as read
     */
    async markAsRead(notificationId, userId) {
        try {
            const [updated] = await Notification.update(
                { is_read: true },
                { where: { id: notificationId, user_id: userId } }
            );
            return updated;
        } catch (err) {
            throw err;
        }
    }

    /**
     * Mark all notifications for a user as read
     */
    async markAllAsRead(userId) {
        try {
            const [updated] = await Notification.update(
                { is_read: true },
                { where: { user_id: userId, is_read: false } }
            );
            return updated;
        } catch (err) {
            throw err;
        }
    }

    /**
     * Create a new notification
     */
    async createNotification(userId, type, referenceId = null) {
        try {
            return await Notification.create({
                user_id: userId,
                type,
                reference_id: referenceId,
                is_read: false,
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get unread notification count for a user
     */
    async getUnreadCount(userId) {
        try {
            return await Notification.count({
                where: { user_id: userId, is_read: false },
            });
        } catch (err) {
            throw err;
        }
    }
}

module.exports = new NotificationRepo();
