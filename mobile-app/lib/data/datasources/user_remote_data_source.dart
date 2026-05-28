import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for user-related backend endpoints.
abstract class UserRemoteDataSource {
  /// GET /user/me — fetch the currently authenticated backend user.
  Future<UserModel> fetchMe();

  /// GET /user/me/points/history - fetch user's recovery points transaction history.
  Future<List<Map<String, dynamic>>> fetchPointsHistory();

  /// GET /user/me/redemptions - fetch user's redemption records.
  Future<List<Map<String, dynamic>>> fetchRedemptions();

  /// POST /user/me/redeem - redeem a reward.
  Future<Map<String, dynamic>> redeemReward(String rewardId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> fetchMe() async {
    try {
      final response = await apiClient.get(ApiConstants.userProfileEndpoint);
      // Backend returns: { success: true, data: { ...user } }
      final data = response['data'];
      if (data == null) {
        throw ServerException('Empty response from /user/me');
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPointsHistory() async {
    try {
      final response = await apiClient.get(ApiConstants.pointsHistoryEndpoint);
      final data = response['data'] as List?;
      if (data == null) return [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw ServerException('Failed to fetch points history: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRedemptions() async {
    try {
      final response = await apiClient.get(ApiConstants.redemptionsEndpoint);
      final data = response['data'] as List?;
      if (data == null) return [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw ServerException('Failed to fetch redemptions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      final response = await apiClient.post(
        ApiConstants.redeemEndpoint,
        body: {'reward_id': rewardId},
      );
      final data = response['data'] as Map<String, dynamic>?;
      return data ?? {};
    } catch (e) {
      throw ServerException('Failed to redeem reward: $e');
    }
  }
}

