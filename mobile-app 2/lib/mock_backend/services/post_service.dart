import '../../domain/entities/post.dart';
import '../mocks/items.mock.dart';
import '../utils/network_simulator.dart';

// ============================================================
// POST SERVICE — Switchable mock / real API
// Toggle USE_MOCK_API in network_simulator.dart
// ============================================================

class PostService {
  // In-memory mutable list
  static final List<Post> _db = List.from(mockPosts);

  // ── GET ALL POSTS (paginated + filtered) ──────────────────
  static Future<ApiResponse<List<Post>>> getAllPosts({
    int page = 1,
    int limit = 10,
    String? postType,
    String? country,
    String? city,
    String? category,
  }) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate(failureRate: 0.05);

      var filtered = List<Post>.from(_db);
      if (postType != null) filtered = filtered.where((p) => p.postType == postType).toList();
      if (country != null) filtered = filtered.where((p) => p.country.toLowerCase().contains(country.toLowerCase())).toList();
      if (city != null) filtered = filtered.where((p) => (p.city ?? '').toLowerCase().contains(city.toLowerCase())).toList();
      if (category != null) filtered = filtered.where((p) => p.category == category).toList();

      final total = filtered.length;
      final start = (page - 1) * limit;
      final end = (start + limit).clamp(0, total);
      final data = start >= total ? <Post>[] : filtered.sublist(start, end);

      return ApiResponse.success(
        data,
        meta: MetaData(page: page, total: total, totalPages: (total / limit).ceil()),
      );
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── GET POST BY ID ─────────────────────────────────────────
  static Future<ApiResponse<Post>> getPostById(String id) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      final post = getMockPostById(id);
      if (post == null) return ApiResponse.error("Post not found", code: 404);
      return ApiResponse.success(post);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── GET USER POSTS ─────────────────────────────────────────
  static Future<ApiResponse<List<Post>>> getUserPosts(String userId) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      final posts = getMockPostsByUser(userId);
      return ApiResponse.success(posts);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── CREATE POST ────────────────────────────────────────────
  static Future<ApiResponse<Post>> createPost(Map<String, dynamic> payload) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();

      // Mimic backend validation
      if (payload['user_id'] == null) return ApiResponse.error("user_id is required", code: 400);
      if (payload['title'] == null || payload['title'].toString().trim().isEmpty) return ApiResponse.error("title is required", code: 400);
      if (payload['country'] == null || payload['country'].toString().trim().length < 2) return ApiResponse.error("country must be at least 2 characters", code: 400);
      if (payload['city'] == null || payload['city'].toString().trim().length < 2) return ApiResponse.error("city must be at least 2 characters", code: 400);
      if (!['lost', 'found'].contains(payload['post_type'])) return ApiResponse.error("post_type must be 'lost' or 'found'", code: 400);

      final newPost = Post(
        id: "uuid-post-${DateTime.now().millisecondsSinceEpoch}",
        userId: payload['user_id'],
        title: payload['title'],
        description: payload['description'] ?? '',
        category: payload['category'] ?? 'Other',
        postType: payload['post_type'],
        imageUrl: payload['image_url'] ?? 'https://placehold.co/400x300/0A3D91/white?text=Item',
        country: payload['country'],
        state: payload['state'],
        city: payload['city'],
        latitude: payload['latitude'],
        longitude: payload['longitude'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _db.insert(0, newPost);
      return ApiResponse.success(newPost);
    } else {
      throw UnimplementedError("Connect real HTTP client here");
    }
  }

  // ── RESET MOCK DB (for testing) ───────────────────────────
  static void resetMockDb() {
    _db.clear();
    _db.addAll(mockPosts);
  }
}
