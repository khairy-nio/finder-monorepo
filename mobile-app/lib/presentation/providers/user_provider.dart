import 'package:flutter/foundation.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../domain/entities/user.dart';

/// Manages the currently authenticated backend user across the app.
///
/// Call [loadUser] right after login/signup to populate [backendUser].
/// Call [clear] on logout so the next user starts fresh.
class UserProvider with ChangeNotifier {
  final UserRemoteDataSource _remoteDataSource;

  UserProvider({required UserRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  // ── State ────────────────────────────────────────────────────
  User? _backendUser;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────
  User? get backendUser => _backendUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the backend user has been loaded successfully.
  bool get isLoaded => _backendUser != null;

  /// Whether the backend user is an admin.
  bool get isAdmin => _backendUser?.isAdmin ?? false;

  // ── Actions ──────────────────────────────────────────────────

  /// Fetches the authenticated user from GET /user/me and stores it.
  ///
  /// Errors are caught silently — callers can check [error] if needed.
  /// Screens should degrade gracefully (fall back to Firebase data) when
  /// [backendUser] is null.
  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _remoteDataSource.fetchMe();
      _backendUser = user;
      _error = null;
      debugPrint('[UserProvider] Loaded backend user: ${user.id} (${user.email})');
    } catch (e) {
      _error = e.toString();
      debugPrint('[UserProvider] Failed to load user: $e');
      // Non-fatal — backendUser stays null; screens will use Firebase fallback.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the stored user — call this on logout.
  void clear() {
    _backendUser = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
    debugPrint('[UserProvider] User state cleared.');
  }

  /// Fetches points history
  Future<List<Map<String, dynamic>>> getPointsHistory() async {
    try {
      return await _remoteDataSource.fetchPointsHistory();
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch points history: $e');
      return [];
    }
  }

  /// Fetches redemptions history
  Future<List<Map<String, dynamic>>> getRedemptions() async {
    try {
      return await _remoteDataSource.fetchRedemptions();
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch redemptions: $e');
      return [];
    }
  }

  /// Redeem a reward from the catalog
  Future<bool> redeemReward(String rewardId) async {
    try {
      await _remoteDataSource.redeemReward(rewardId);
      // Re-fetch user profile to sync the points balance instantly in the App Header!
      await loadUser();
      return true;
    } catch (e) {
      debugPrint('[UserProvider] Failed to redeem reward: $e');
      return false;
    }
  }
}

