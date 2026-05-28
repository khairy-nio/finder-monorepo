import '../types/post.dart';
import '../mocks/items.mock.dart';
import '../utils/network_simulator.dart';

class ItemService {
  // In-memory mock database
  static final List<PostDto> _mockDb = <PostDto>[];

  Future<ApiResponse<List<PostDto>>> getItems({int page = 1, int limit = 10}) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      
      // Pagination Simulation
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      if (startIndex >= _mockDb.length) {
         return ApiResponse.success(
           [], 
           meta: MetaData(page: page, total: _mockDb.length, totalPages: (_mockDb.length / limit).ceil())
         );
      }
      
      final paginatedData = _mockDb.sublist(
        startIndex, 
        endIndex > _mockDb.length ? _mockDb.length : endIndex
      );

      return ApiResponse.success(
        paginatedData,
        meta: MetaData(
          page: page, 
          total: _mockDb.length, 
          totalPages: (_mockDb.length / limit).ceil(),
        )
      );
    } else {
      // Real API HTTP Request logic would go here
      throw UnimplementedError("Real API not connected yet");
    }
  }

  Future<ApiResponse<PostDto>> getItemById(String id) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      final item = _mockDb.where((i) => i.id == id).firstOrNull;
      
      if (item == null) {
        return ApiResponse.error("Post not found", code: 404);
      }
      return ApiResponse.success(item);
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }

  Future<ApiResponse<PostDto>> createItem(Map<String, dynamic> payload) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      
      // Mimic Backend Validation Requirements
      if (payload['user_id'] == null) return ApiResponse.error("user_id is required", code: 400);
      if (payload['title'] == null) return ApiResponse.error("title is required", code: 400);
      if (payload['country'] == null) return ApiResponse.error("country is required", code: 400);
      if (payload['city'] == null) return ApiResponse.error("city is required", code: 400);
      if (payload['post_type'] == null || !['lost', 'found'].contains(payload['post_type'])) {
        return ApiResponse.error("post_type must be 'lost' or 'found'", code: 400);
      }

      final newItem = PostDto(
        id: "uuid-post-${DateTime.now().millisecondsSinceEpoch}",
        userId: payload['user_id'],
        title: payload['title'],
        description: payload['description'],
        category: payload['category'],
        latitude: payload['latitude'],
        longitude: payload['longitude'],
        imageUrl: payload['image_url'],
        status: "active",
        postType: payload['post_type'],
        country: payload['country'],
        state: payload['state'],
        city: payload['city'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _mockDb.insert(0, newItem);
      return ApiResponse.success(newItem);
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }
}
