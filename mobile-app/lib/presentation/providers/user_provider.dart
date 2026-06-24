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

  // ── State ─────────────────────────────────────────────────────────────────
  User? _backendUser;
  PointsSummary? _pointsSummary;
  Map<String, dynamic>? _cashTiersData;
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  User? get backendUser => _backendUser;
  PointsSummary? get pointsSummary => _pointsSummary;
  Map<String, dynamic>? get cashTiersData => _cashTiersData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the backend user has been loaded successfully.
  bool get isLoaded => _backendUser != null;

  /// Whether the backend user is an admin.
  bool get isAdmin => _backendUser?.isAdmin ?? false;

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Fetches the authenticated user from GET /user/me and stores it.
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the stored user — call this on logout.
  void clear() {
    _backendUser = null;
    _pointsSummary = null;
    _cashTiersData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
    debugPrint('[UserProvider] User state cleared.');
  }

  // ── Recovery Points ───────────────────────────────────────────────────────

  /// Fetches the points balance + summary stats from GET /user/me/points.
  /// Returns the [PointsSummary] or null on failure.
  Future<PointsSummary?> loadPointsSummary() async {
    try {
      final summary = await _remoteDataSource.fetchPointsSummary();
      _pointsSummary = summary;
      notifyListeners();
      return summary;
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch points summary: $e');
      return null;
    }
  }

  /// Fetches paginated points transaction history.
  Future<List<Map<String, dynamic>>> getPointsHistory({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      return await _remoteDataSource.fetchPointsHistory(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch points history: $e');
      return [];
    }
  }

  /// Fetches available cash redemption tiers from GET /user/me/points/tiers.
  /// Returns the raw data map including: tiers list, wallet_providers, points_per_egp.
  Future<Map<String, dynamic>> getCashTiers() async {
    try {
      final data = await _remoteDataSource.fetchCashTiers();
      _cashTiersData = data;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch cash tiers: $e');
      return {};
    }
  }

  // ── Wallet Cash Redemption ────────────────────────────────────────────────

  /// Submit a wallet cash redemption request.
  ///
  /// [tierPoints]     — must be one of 500 | 1000 | 1500 | 2000
  /// [walletProvider] — e.g. 'vodafone_cash', 'instapay', etc.
  /// [walletNumber]   — user's mobile wallet number
  ///
  /// Returns the response data map on success, or null on failure.
  /// Call [loadUser] and [loadPointsSummary] after a successful redemption
  /// to sync the points balance.
  Future<Map<String, dynamic>?> redeemCash({
    required int tierPoints,
    required String walletProvider,
    required String walletNumber,
  }) async {
    try {
      final data = await _remoteDataSource.redeemCash(
        tierPoints:     tierPoints,
        walletProvider: walletProvider,
        walletNumber:   walletNumber,
      );
      // Sync the points balance immediately after a successful redemption
      await loadUser();
      await loadPointsSummary();
      return data;
    } catch (e) {
      debugPrint('[UserProvider] Failed to redeem cash: $e');
      return null;
    }
  }

  /// Fetches the user's wallet cash redemption history.
  Future<List<Map<String, dynamic>>> getRedemptions({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      return await _remoteDataSource.fetchRedemptions(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('[UserProvider] Failed to fetch redemptions: $e');
      return [];
    }
  }
}
