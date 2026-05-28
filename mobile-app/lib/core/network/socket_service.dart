import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_endpoints.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _authToken;
  String? activeChatId; // Tracks the currently open chat screen

  // Set the auth token which should be retrieved from Firebase Auth
  void setAuthToken(String token) {
    _authToken = token;
  }

  void connect() {
    if (_authToken == null) {
      print('SocketService Error: Cannot connect without auth token');
      return;
    }

    if (_socket != null && _socket!.connected) return;

    if (_socket == null) {
      _socket = IO.io(
        ApiEndpoints.baseUrl.replaceAll('/api/v1', ''), // Socket connects to root, not api/v1
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': _authToken}) // Pass token to backend socket middleware
            .build(),
      );

      _socket!.onConnect((_) {
        print('Connected to Socket.io Server');
      });

      _socket!.onDisconnect((_) {
        print('Disconnected from Socket.io Server');
      });

      _socket!.onError((data) {
        print('Socket Error: $data');
      });
    }

    if (!_socket!.connected) {
      _socket!.connect();
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      // DO NOT set to null so listeners aren't lost on reconnect
    }
  }

  void _emitWhenConnected(String event, dynamic data) {
    if (_socket == null) return;
    if (_socket!.connected) {
      _socket!.emit(event, data);
    } else {
      _socket!.once('connect', (_) {
        _socket!.emit(event, data);
      });
    }
  }

  void joinChat(String chatId) => _emitWhenConnected('join_chat', {'chatId': chatId});
  void leaveChat(String chatId) => _emitWhenConnected('leave_chat', {'chatId': chatId});
  void sendMessage(String chatId, String content) => _emitWhenConnected('send_message', {'chatId': chatId, 'content': content, 'client_msg_id': DateTime.now().millisecondsSinceEpoch.toString()});
  void sendTypingStart(String chatId) => _emitWhenConnected('typing_start', {'chatId': chatId});
  void sendTypingStop(String chatId) => _emitWhenConnected('typing_stop', {'chatId': chatId});
  void markMessageRead(String chatId, String messageId) => _emitWhenConnected('message_read', {'chatId': chatId, 'messageId': messageId});
  void checkUserStatus(String userId) => _emitWhenConnected('check_user_status', {'userId': userId});

  // Listeners management
  void on(String event, dynamic Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event, [dynamic Function(dynamic)? callback]) {
    _socket?.off(event, callback);
  }

  // Generic Event Listener (Replaces onNewMessage etc.)
  void onEvent(dynamic Function(dynamic) callback) => on('event', callback);
  void offEvent([dynamic Function(dynamic)? callback]) => off('event', callback);
  
  // Dispose all (use carefully)
  void removeListeners() {
    _socket?.clearListeners();
  }
}
