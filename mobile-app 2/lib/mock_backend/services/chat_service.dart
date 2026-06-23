import '../mocks/chats.mock.dart';
import '../../domain/entities/chat_message.dart';
import '../utils/network_simulator.dart';

// ============================================================
// CHAT SERVICE — Switchable mock / real API
// ============================================================

class ChatService {
  static final List<MockChat> _db = List.from(mockChats);

  // ── GET ALL CHATS FOR CURRENT USER ─────────────────────────
  static Future<ApiResponse<List<MockChat>>> getUserChats(String userId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 200, maxDelayMs: 600);
      final chats = _db.where((c) => c.user1 == userId || c.user2 == userId).toList();
      return ApiResponse.success(chats);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── GET MESSAGES IN A CHAT ─────────────────────────────────
  static Future<ApiResponse<List<ChatMessage>>> getChatMessages(String chatId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 200, maxDelayMs: 600);
      try {
        final chat = _db.firstWhere((c) => c.id == chatId);
        return ApiResponse.success(chat.messages);
      } catch (_) {
        return ApiResponse.error("Chat not found", code: 404);
      }
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── SEND A MESSAGE ─────────────────────────────────────────
  static Future<ApiResponse<ChatMessage>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 100, maxDelayMs: 400, failureRate: 0.02);
      try {
        final chat = _db.firstWhere((c) => c.id == chatId);
        final newMessage = ChatMessage(
          id: "msg-${DateTime.now().millisecondsSinceEpoch}",
          chatId: chatId,
          senderId: senderId,
          message: content,
          timestamp: DateTime.now(),
        );
        chat.messages.add(newMessage);
        return ApiResponse.success(newMessage);
      } catch (_) {
        return ApiResponse.error("Chat not found", code: 404);
      }
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }
}
