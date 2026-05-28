import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/chat_message_model.dart';

/// Remote Data Source for Chat operations
abstract class ChatRemoteDataSource {
  Future<String> startChat({
    required String otherUserId,
  });

  Future<List<ChatMessageModel>> getChatMessages(String chatId);

  Future<ChatMessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  });

  Future<void> markAsRead(String chatId, String userId);

  /// GET /chat/my-chats — returns a list of chat maps from the backend.
  Future<List<Map<String, dynamic>>> getMyChats();

  Future<Map<String, dynamic>> checkRequestStatus(String postId);
  Future<void> sendContactRequest(String receiverId, String postId, String introMessage);
  Future<String?> getChatWithUser(String userId);

  /// GET /chat/:chatId — returns raw chat map with participant data.
  Future<Map<String, dynamic>?> getChatMetadata(String chatId);
}

/// Implementation of ChatRemoteDataSource
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<String> startChat({
    required String otherUserId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.createChatEndpoint,
        body: {'other_user_id': otherUserId},
      );
      final data = response['data'] as Map<String, dynamic>;
      return data['id'] as String;
    } catch (e) {
      throw ServerException('Failed to start chat: $e');
    }
  }

  @override
  Future<List<ChatMessageModel>> getChatMessages(String chatId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.chatEndpoint}/$chatId/messages',
      );
      final List<dynamic> messagesJson = response['data'] as List<dynamic>? ?? [];
      return messagesJson
          .map(
            (json) => ChatMessageModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to get chat messages: $e');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.chatEndpoint}/$chatId/send',
        body: {'content': message},
      );
      return ChatMessageModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await apiClient.post(
        '${ApiConstants.chatEndpoint}/$chatId/read',
        body: {'user_id': userId},
      );
    } catch (e) {
      throw ServerException('Failed to mark as read: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMyChats() async {
    try {
      final response = await apiClient.get(ApiConstants.myChatsEndpoint);
      final List<dynamic> chatsJson =
          response['data'] as List<dynamic>? ?? [];
      return chatsJson
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch chats: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> checkRequestStatus(String postId) async {
    try {
      final response = await apiClient.get('${ApiConstants.checkContactRequestEndpoint}/$postId');
      if (response['success'] == true) {
        if (response['data'] != null) {
          return response['data'] as Map<String, dynamic>;
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> sendContactRequest(String receiverId, String postId, String introMessage) async {
    try {
      final body = {
        'receiver_id': receiverId,
        'post_id': postId,
      };
      
      if (introMessage.trim().isNotEmpty) {
        body['intro_message'] = introMessage.trim();
      }

      await apiClient.post(
        ApiConstants.sendContactRequestEndpoint,
        body: body,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to send request: $e');
    }
  }

  @override
  Future<String?> getChatWithUser(String userId) async {
    try {
      final response = await apiClient.get('${ApiConstants.chatEndpoint}/with/$userId');
      if (response['success'] == true && response['data'] != null) {
        return response['data']['id'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getChatMetadata(String chatId) async {
    try {
      final response = await apiClient.get('${ApiConstants.chatEndpoint}/$chatId');
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
