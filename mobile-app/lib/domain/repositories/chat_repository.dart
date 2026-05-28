import '../entities/chat_message.dart';
import '../../core/errors/failures.dart';
import '../repositories/post_repository.dart'; // For Either class

/// Chat Repository Interface - Domain Layer
abstract class ChatRepository {
  /// Start a new chat between two users
  Future<Either<Failure, String>> startChat({
    required String userId1,
    required String userId2,
    required String postId,
  });

  /// Get chat messages
  Future<Either<Failure, List<ChatMessage>>> getChatMessages(String chatId);

  /// Send a message
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  });

  /// Mark messages as read
  Future<Either<Failure, void>> markAsRead(String chatId, String userId);
}
