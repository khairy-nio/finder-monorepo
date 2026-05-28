const { randomUUID } = require('crypto');

const EVENT_VERSION = 1;

const toIsoString = (value) => {
    if (!value) return null;
    if (typeof value === 'string') return value;
    if (value instanceof Date) return value.toISOString();
    return new Date(value).toISOString();
};

const normalizeUser = (user) => {
    if (!user) return null;
    return {
        id: user.id,
        name: user.name || null,
        role: user.role || null
    };
};

const normalizeConversation = (chat) => {
    if (!chat) return null;
    return {
        id: chat.id,
        post_id: chat.post_id || null,
        user_1: chat.user_1 || null,
        user_2: chat.user_2 || null
    };
};

const normalizeMessage = (message) => {
    if (!message) return null;
    return {
        id: message.id,
        chat_id: message.chat_id,
        sender_id: message.sender_id,
        content: message.content,
        client_msg_id: message.client_msg_id || null,
        created_at: toIsoString(message.created_at || message.createdAt)
    };
};

const normalizeNotification = (notification) => {
    if (!notification) return null;
    return {
        id: notification.id,
        user_id: notification.user_id,
        type: notification.type,
        reference_id: notification.reference_id || null,
        message: notification.message || null,
        is_read: notification.is_read || false,
        created_at: toIsoString(notification.created_at || notification.createdAt)
    };
};

const buildEvent = ({
    eventType,
    actor = null,
    conversation = null,
    data = {},
    eventId = null,
    dedupeKey = null,
    emittedAt = new Date()
}) => {
    return {
        event_id: eventId || randomUUID(),
        event_type: eventType,
        version: EVENT_VERSION,
        emitted_at: toIsoString(emittedAt),
        actor,
        conversation,
        data,
        dedupe_key: dedupeKey || null
    };
};

module.exports = {
    EVENT_VERSION,
    buildEvent,
    normalizeUser,
    normalizeConversation,
    normalizeMessage,
    normalizeNotification
};
