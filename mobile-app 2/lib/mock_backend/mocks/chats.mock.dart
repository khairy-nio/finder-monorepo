import '../../domain/entities/chat_message.dart';
import 'users.mock.dart';

// ============================================================
// MOCK CHATS — Chat conversations for the current user
// Uses ChatMessage entity (field: message, timestamp)
// ============================================================

class MockChat {
  final String id;
  final String user1;
  final String user2;
  final String otherUserName;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final List<ChatMessage> messages;

  MockChat({
    required this.id,
    required this.user1,
    required this.user2,
    required this.otherUserName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.messages,
  });
}

// Current user (Ahmed Ali, uuid-user-01) chats
final List<MockChat> mockChats = [
  MockChat(
    id: "uuid-chat-01",
    user1: mockUsers[0].id, // Ahmed Ali
    user2: mockUsers[2].id, // John Smith
    otherUserName: mockUsers[2].name!,
    lastMessage: "I found it near the campus library",
    time: "10:33 AM",
    unreadCount: 2,
    isOnline: true,
    messages: [
      ChatMessage(
        id: "msg-01-01",
        chatId: "uuid-chat-01",
        senderId: mockUsers[2].id,
        message: "Hi! I think I found your wallet near the library.",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: "msg-01-02",
        chatId: "uuid-chat-01",
        senderId: mockUsers[0].id,
        message: "Oh really?! Can you describe it?",
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      ),
      ChatMessage(
        id: "msg-01-03",
        chatId: "uuid-chat-01",
        senderId: mockUsers[2].id,
        message: "I found it near the campus library",
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ],
  ),
  MockChat(
    id: "uuid-chat-02",
    user1: mockUsers[0].id,
    user2: mockUsers[1].id, // Sarah Mohamed
    otherUserName: mockUsers[1].name!,
    lastMessage: "Thanks for helping me find my wallet!",
    time: "Yesterday",
    unreadCount: 0,
    isOnline: false,
    messages: [
      ChatMessage(
        id: "msg-02-01",
        chatId: "uuid-chat-02",
        senderId: mockUsers[0].id,
        message: "I saw your post and I think I have your wallet.",
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      ChatMessage(
        id: "msg-02-02",
        chatId: "uuid-chat-02",
        senderId: mockUsers[1].id,
        message: "Thanks for helping me find my wallet!",
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ),
    ],
  ),
  MockChat(
    id: "uuid-chat-03",
    user1: mockUsers[0].id,
    user2: mockUsers[4].id, // Omar Khaled
    otherUserName: mockUsers[4].name!,
    lastMessage: "Is this your phone?",
    time: "2 days ago",
    unreadCount: 1,
    isOnline: true,
    messages: [
      ChatMessage(
        id: "msg-03-01",
        chatId: "uuid-chat-03",
        senderId: mockUsers[4].id,
        message: "Is this your phone?",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
  ),
  MockChat(
    id: "uuid-chat-04",
    user1: mockUsers[0].id,
    user2: mockUsers[7].id, // Layla
    otherUserName: mockUsers[7].name!,
    lastMessage: "I'll be there in 10 minutes",
    time: "Monday",
    unreadCount: 0,
    isOnline: false,
    messages: [
      ChatMessage(
        id: "msg-04-01",
        chatId: "uuid-chat-04",
        senderId: mockUsers[0].id,
        message: "I am at the agreed location, waiting for you.",
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      ),
      ChatMessage(
        id: "msg-04-02",
        chatId: "uuid-chat-04",
        senderId: mockUsers[7].id,
        message: "I'll be there in 10 minutes",
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 55)),
      ),
    ],
  ),
];
