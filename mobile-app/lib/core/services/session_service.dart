import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _sessionKey = 'app_session_expiration';

  /// Saves the session expiration timestamp (7 days from now).
  Future<void> saveSession() async {
    final expirationDate = DateTime.now().add(const Duration(days: 7));
    await _storage.write(key: _sessionKey, value: expirationDate.toIso8601String());
  }

  /// Checks if the session is valid (exists and hasn't expired).
  Future<bool> isSessionValid() async {
    final expirationString = await _storage.read(key: _sessionKey);
    if (expirationString == null) return false;

    final expirationDate = DateTime.tryParse(expirationString);
    if (expirationDate == null) return false;

    return DateTime.now().isBefore(expirationDate);
  }

  /// Clears the session entirely.
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
