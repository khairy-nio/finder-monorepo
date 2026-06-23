import 'users.mock.dart';

// ============================================================
// MOCK NOTIFICATIONS — 15 realistic records
// Matches backend Notification model exactly
// Types: 'match_found', 'contact_request', 'contact_accepted', 'post_resolved'
// ============================================================

class MockNotification {
  final String id;
  final String userId;
  final String type;       // matches backend ENUM
  final String? referenceId;
  bool isRead;             // mutable for UI interaction
  final DateTime createdAt;

  // UI-only helpers (computed, not from backend)
  final String displayTitle;
  final String displayMessage;

  MockNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    required this.displayTitle,
    required this.displayMessage,
  });
}

final List<MockNotification> mockNotifications = [
  MockNotification(
    id: "uuid-notif-01",
    userId: mockUsers[0].id, // Ahmed Ali
    type: "match_found",
    referenceId: "uuid-post-01",
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    displayTitle: "AI Match Found! 🎉",
    displayMessage: "Your lost wallet may have been found near Cairo University.",
  ),
  MockNotification(
    id: "uuid-notif-02",
    userId: mockUsers[0].id,
    type: "contact_request",
    referenceId: "uuid-chat-01",
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    displayTitle: "Contact Request",
    displayMessage: "John Smith wants to contact you about your lost post.",
  ),
  MockNotification(
    id: "uuid-notif-03",
    userId: mockUsers[0].id,
    type: "contact_accepted",
    referenceId: "uuid-chat-02",
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    displayTitle: "Request Accepted",
    displayMessage: "Sarah Mohamed accepted your contact request. You can now chat!",
  ),
  MockNotification(
    id: "uuid-notif-04",
    userId: mockUsers[0].id,
    type: "post_resolved",
    referenceId: "uuid-post-09",
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    displayTitle: "Post Resolved",
    displayMessage: "Your 'Found Child's Toy' post has been marked as resolved.",
  ),
  MockNotification(
    id: "uuid-notif-05",
    userId: mockUsers[0].id,
    type: "match_found",
    referenceId: "uuid-post-05",
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    displayTitle: "New AI Match Found!",
    displayMessage: "A blue JanSport backpack was reported found near Cairo Airport.",
  ),
];
