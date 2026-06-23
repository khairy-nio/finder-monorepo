import '../mocks/notifications.mock.dart';
import '../utils/network_simulator.dart';

// ============================================================
// NOTIFICATION SERVICE — Switchable mock / real API
// ============================================================

class NotificationService {
  static final List<MockNotification> _db = List.from(mockNotifications);

  // ── GET ALL NOTIFICATIONS FOR USER ─────────────────────────
  static Future<ApiResponse<List<MockNotification>>> getUserNotifications(String userId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 200, maxDelayMs: 700);
      final notifs = _db.where((n) => n.userId == userId).toList();
      return ApiResponse.success(notifs);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── MARK AS READ ──────────────────────────────────────────
  static Future<ApiResponse<bool>> markAsRead(String notifId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 100, maxDelayMs: 300, failureRate: 0.0);
      final idx = _db.indexWhere((n) => n.id == notifId);
      if (idx == -1) return ApiResponse.error("Notification not found", code: 404);
      _db[idx].isRead = true;
      return ApiResponse.success(true);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── MARK ALL AS READ ──────────────────────────────────────
  static Future<ApiResponse<bool>> markAllAsRead(String userId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(minDelayMs: 200, maxDelayMs: 400, failureRate: 0.0);
      for (final n in _db) {
        if (n.userId == userId) n.isRead = true;
      }
      return ApiResponse.success(true);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── UNREAD COUNT ───────────────────────────────────────────
  static int getUnreadCount(String userId) {
    return _db.where((n) => n.userId == userId && !n.isRead).length;
  }
}
