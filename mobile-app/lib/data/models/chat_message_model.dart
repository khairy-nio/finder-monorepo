import '../../domain/entities/chat_message.dart';

/// Chat Message Model - Data Layer
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.message,
    required super.timestamp,
    super.isRead,
  });

  /// From JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['content'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': message,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// From Entity
  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      id: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      message: message.message,
      timestamp: message.timestamp,
      isRead: message.isRead,
    );
  }
}
