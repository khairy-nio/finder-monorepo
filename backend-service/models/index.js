const User = require('./User.model');
const Post = require('./post.model');
const EmbeddingReference = require('./EmbeddingReference.model');
const ContactRequest = require('./ContactRequest.model');
const Chat = require('./Chat.model');
const Message = require('./Message.model');
const Notification = require('./Notification.model');
const Report = require('./Report.model');
const AdminAction = require('./AdminAction.model');
const UserVerification = require('./UserVerification.model');

// ========== USER RELATIONSHIPS ==========
// One User has Many Posts
User.hasMany(Post, { foreignKey: 'user_id', as: 'posts', onDelete: 'CASCADE' });
Post.belongsTo(User, { foreignKey: 'user_id', as: 'owner' });

// One User has Many Contact Requests (as sender)
User.hasMany(ContactRequest, { foreignKey: 'sender_id', as: 'sentRequests', onDelete: 'CASCADE' });
ContactRequest.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });

// One User has Many Contact Requests (as receiver)
User.hasMany(ContactRequest, { foreignKey: 'receiver_id', as: 'receivedRequests', onDelete: 'CASCADE' });
ContactRequest.belongsTo(User, { foreignKey: 'receiver_id', as: 'receiver' });

// One User has Many Notifications
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications', onDelete: 'CASCADE' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// One User has Many Reports (as reporter)
User.hasMany(Report, { foreignKey: 'reporter_id', as: 'submittedReports', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'reporter_id', as: 'reporter' });

// One User has Many Reports (as reported)
User.hasMany(Report, { foreignKey: 'reported_user_id', as: 'receivedReports', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'reported_user_id', as: 'reportedUser' });

// One User has One Verification
User.hasOne(UserVerification, { foreignKey: 'user_id', as: 'verification', onDelete: 'CASCADE' });
UserVerification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// ========== POST RELATIONSHIPS ==========
// One Post has One Embedding Reference
Post.hasOne(EmbeddingReference, { foreignKey: 'post_id', as: 'embedding', onDelete: 'CASCADE' });
EmbeddingReference.belongsTo(Post, { foreignKey: 'post_id', as: 'post' });

// One Post has Many Contact Requests
Post.hasMany(ContactRequest, { foreignKey: 'post_id', as: 'contactRequests', onDelete: 'CASCADE' });
ContactRequest.belongsTo(Post, { foreignKey: 'post_id', as: 'post' });

// ========== CHAT RELATIONSHIPS ==========
// One Post has Many Chats
Post.hasMany(Chat, { foreignKey: 'post_id', as: 'chats', onDelete: 'CASCADE' });
Chat.belongsTo(Post, { foreignKey: 'post_id', as: 'post' });

// One Chat has Many Messages
Chat.hasMany(Message, { foreignKey: 'chat_id', as: 'messages', onDelete: 'CASCADE' });
Message.belongsTo(Chat, { foreignKey: 'chat_id', as: 'chat' });

// Chat belongs to Two Users (Many-to-Many through user_1 and user_2)
User.hasMany(Chat, { foreignKey: 'user_1', as: 'chatsAsFirstUser' });
User.hasMany(Chat, { foreignKey: 'user_2', as: 'chatsAsSecondUser' });
Chat.belongsTo(User, { foreignKey: 'user_1', as: 'firstUser' });
Chat.belongsTo(User, { foreignKey: 'user_2', as: 'secondUser' });

// Message belongs to User (sender)
User.hasMany(Message, { foreignKey: 'sender_id', as: 'sentMessages', onDelete: 'CASCADE' });
Message.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });

// ========== REPORT-POST RELATIONSHIPS ==========
// One Post has Many Reports
Post.hasMany(Report, { foreignKey: 'reported_post_id', as: 'receivedReports', onDelete: 'CASCADE' });
Report.belongsTo(Post, { foreignKey: 'reported_post_id', as: 'reportedPost' });

// One Message has Many Reports
Message.hasMany(Report, { foreignKey: 'reported_message_id', as: 'receivedReports', onDelete: 'CASCADE' });
Report.belongsTo(Message, { foreignKey: 'reported_message_id', as: 'reportedMessage' });

// One Chat has Many Reports
Chat.hasMany(Report, { foreignKey: 'reported_chat_id', as: 'receivedReports', onDelete: 'CASCADE' });
Report.belongsTo(Chat, { foreignKey: 'reported_chat_id', as: 'reportedChat' });

// ========== ADMIN RELATIONSHIPS ==========
AdminAction.belongsTo(User, { foreignKey: 'admin_id', as: 'admin' });

// ========== RECOVERY POINTS RELATIONSHIPS ==========
const RecoveryPointTransaction = require('./RecoveryPointTransaction.model');
const RecoveryRedemption = require('./RecoveryRedemption.model');

User.hasMany(RecoveryPointTransaction, { foreignKey: 'user_id', as: 'pointTransactions', onDelete: 'CASCADE' });
RecoveryPointTransaction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

Post.hasMany(RecoveryPointTransaction, { foreignKey: 'post_id', as: 'pointTransactions', onDelete: 'SET NULL' });
RecoveryPointTransaction.belongsTo(Post, { foreignKey: 'post_id', as: 'associatedPost' });


User.hasMany(RecoveryRedemption, { foreignKey: 'user_id', as: 'redemptions', onDelete: 'CASCADE' });
RecoveryRedemption.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Export all models
module.exports = {
    User,
    Post,
    EmbeddingReference,
    ContactRequest,
    Chat,
    Message,
    Notification,
    Report,
    AdminAction,
    UserVerification,
    RecoveryPointTransaction,
    RecoveryRedemption
};