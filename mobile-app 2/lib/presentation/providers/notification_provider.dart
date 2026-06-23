import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  bool _initialized = false;
  
  int get unreadCount => _unreadCount;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _fetchUnreadCount();
    
    // Listen to new notifications
    SocketService().on('new_notification', (data) {
      _unreadCount++;
      notifyListeners();
    });
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final token = await AuthService.instance.getIdToken();
      if (token == null) return;
      final apiClient = ApiClient(tokenProvider: () async => token);
      final response = await apiClient.get(ApiConstants.notificationUnreadCountEndpoint);
      if (response['success'] == true) {
        _unreadCount = int.tryParse(response['data']['count'].toString()) ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  void markAsRead() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    if (_unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
