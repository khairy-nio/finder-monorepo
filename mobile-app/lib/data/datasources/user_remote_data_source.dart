import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Transfer Objects for the new redemption system
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one available cash redemption tier.
/// Returned by GET /user/me/points/tiers
class RedemptionTier {
  final int points;
  final double cashAmountEgp;
  final String label;
  final String description;

  const RedemptionTier({
    required this.points,
    required this.cashAmountEgp,
    required this.label,
    required this.description,
  });

  factory RedemptionTier.fromJson(Map<String, dynamic> json) {
    return RedemptionTier(
      points: (json['points'] as num).toInt(),
      cashAmountEgp: (json['cash_amount_egp'] as num).toDouble(),
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Response payload from GET /user/me/points
class PointsSummary {
  final int currentBalance;
  final int totalEarned;
  final int totalRedeemed;
  final int pendingRedemptions;
  final int pendingPoints;
  final double pendingEgp;

  const PointsSummary({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.pendingRedemptions,
    required this.pendingPoints,
    required this.pendingEgp,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    return PointsSummary(
      currentBalance: (json['current_balance'] as num?)?.toInt() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toInt() ?? 0,
      totalRedeemed: (json['total_redeemed'] as num?)?.toInt() ?? 0,
      pendingRedemptions: (json['pending_redemptions'] as num?)?.toInt() ?? 0,
      pendingPoints: (json['pending_points'] as num?)?.toInt() ?? 0,
      pendingEgp: (json['pending_egp'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract interface
// ─────────────────────────────────────────────────────────────────────────────

/// Remote data source for user-related backend endpoints.
abstract class UserRemoteDataSource {
  /// GET /user/me — fetch the currently authenticated backend user.
  Future<UserModel> fetchMe();

  /// GET /user/me/points — fetch user's point balance + summary stats.
  Future<PointsSummary> fetchPointsSummary();

  /// GET /user/me/points/history — fetch paginated transaction history.
  Future<List<Map<String, dynamic>>> fetchPointsHistory({int limit, int offset});

  /// GET /user/me/points/tiers — fetch available cash redemption tiers.
  Future<Map<String, dynamic>> fetchCashTiers();

  /// POST /user/me/redeem — submit a wallet cash redemption request.
  /// Body: { tier_points, wallet_provider, wallet_number }
  Future<Map<String, dynamic>> redeemCash({
    required int tierPoints,
    required String walletProvider,
    required String walletNumber,
  });

  /// GET /user/me/redemptions — fetch user's wallet redemption history.
  Future<List<Map<String, dynamic>>> fetchRedemptions({int limit, int offset});
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> fetchMe() async {
    try {
      final response = await apiClient.get(ApiConstants.userProfileEndpoint);
      final data = response['data'];
      if (data == null) throw ServerException('Empty response from /user/me');
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<PointsSummary> fetchPointsSummary() async {
    try {
      final response = await apiClient.get(ApiConstants.pointsSummaryEndpoint);
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) throw ServerException('Empty response from /user/me/points');
      return PointsSummary.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to fetch points summary: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPointsHistory({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.pointsHistoryEndpoint}?limit=$limit&offset=$offset',
      );
      final data = response['data'] as List?;
      if (data == null) return [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw ServerException('Failed to fetch points history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchCashTiers() async {
    try {
      final response = await apiClient.get(ApiConstants.pointsTiersEndpoint);
      final data = response['data'] as Map<String, dynamic>?;
      return data ?? {};
    } catch (e) {
      throw ServerException('Failed to fetch cash tiers: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> redeemCash({
    required int tierPoints,
    required String walletProvider,
    required String walletNumber,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.redeemEndpoint,
        body: {
          'tier_points':     tierPoints,
          'wallet_provider': walletProvider,
          'wallet_number':   walletNumber,
        },
      );
      final data = response['data'] as Map<String, dynamic>?;
      return data ?? {};
    } catch (e) {
      throw ServerException('Failed to submit cash redemption: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRedemptions({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.redemptionsEndpoint}?limit=$limit&offset=$offset',
      );
      final data = response['data'] as List?;
      if (data == null) return [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw ServerException('Failed to fetch redemption history: $e');
    }
  }
}
