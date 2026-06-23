import '../types/user.dart';
import '../mocks/users.mock.dart';
import '../utils/network_simulator.dart';

class UserService {
  // In-memory mock database
  static final List<UserDto> _mockDb = List.from(mockUsers);

  Future<ApiResponse<UserDto>> getUserById(String id) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      final user = _mockDb.where((u) => u.id == id).firstOrNull;
      
      if (user == null) {
        return ApiResponse.error("User not found", code: 404);
      }
      return ApiResponse.success(user);
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }

  Future<ApiResponse<UserDto>> updateUserProfile(String id, Map<String, dynamic> updates) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      
      final index = _mockDb.indexWhere((u) => u.id == id);
      if (index == -1) return ApiResponse.error("User not found", code: 404);

      // Validation
      if (updates.containsKey('national_id') && updates['national_id'].toString().length != 14) {
        return ApiResponse.error("National ID must be exactly 14 characters", code: 400);
      }

      final currentUser = _mockDb[index];
      
      final updatedUser = UserDto(
        id: currentUser.id,
        firebaseUid: currentUser.firebaseUid,
        name: updates['name'] ?? currentUser.name,
        email: updates['email'] ?? currentUser.email,
        role: currentUser.role, // role shouldn't be updated by standard profile update
        verified: currentUser.verified,
        trustScore: currentUser.trustScore,
        nationalId: updates['national_id'] ?? currentUser.nationalId,
        phoneNumber: updates['phone_number'] ?? currentUser.phoneNumber,
        idImageUrl: updates['id_image_url'] ?? currentUser.idImageUrl,
        verificationStatus: currentUser.verificationStatus,
        createdAt: currentUser.createdAt,
      );

      _mockDb[index] = updatedUser;
      return ApiResponse.success(updatedUser);
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }
}
