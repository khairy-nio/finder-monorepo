import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/post.dart';
import '../models/post_model.dart';
import '../models/search_result_model.dart';
import '../models/feed_post_model.dart';

/// Remote Data Source for Post operations
abstract class PostRemoteDataSource {
  Future<PostModel> createPost({
    required String title,
    required String description,
    required String category,
    required String postType,
    required String imagePath,
    required String country,
    String? state,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    String? location,
  });

  Future<PostModel> getPostById(String postId);
  Future<List<PostModel>> getAllPosts({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  });
  Future<List<PostModel>> getUserPosts(String userId);
  Future<List<SearchResultModel>> searchByImage({
    required String imagePath,
    required String type,
    required String country,
    String? state,
    String? city,
    String? area,
    String? category,
    double? latitude,
    double? longitude,
  });
  Future<PostModel> updatePost(Post post);
  Future<void> deletePost(String postId);
  Future<void> updatePostStatus(String postId, String status);

  // ─── Secure Feed Methods ──────────────────────────────────────────────────
  Future<List<FeedPost>> getPublicFeed({
    String? type,
    String? category,
    String? country,
    String? city,
    int limit,
    int offset,
  });
  Future<List<Map<String, dynamic>>> getVerificationQuestions(String postId);
  Future<void> updateVerificationQuestions(
      String postId, List<Map<String, dynamic>> questions);
  Future<void> sendClaimRequest({
    required String receiverId,
    required String postId,
    String? introMessage,
    List<Map<String, dynamic>>? verificationAnswers,
  });
}

/// Implementation of PostRemoteDataSource
class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient apiClient;

  PostRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PostModel> createPost({
    required String title,
    required String description,
    required String category,
    required String postType,
    required String imagePath,
    required String country,
    String? state,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    try {
      final fields = <String, String>{
        'title': title,
        'description': description,
        'category': category,
        'post_type': postType,
        'country': country,
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (location != null) 'location': location,
      };
      final response = await apiClient.postMultipart(
        ApiConstants.createPostEndpoint,
        filePath: imagePath,
        fields: fields,
      );
      return PostModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to create post: $e');
    }
  }

  @override
  Future<PostModel> getPostById(String postId) async {
    try {
      final response =
          await apiClient.get('${ApiConstants.postDetailEndpoint}/$postId');
      return PostModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to get post: $e');
    }
  }

  @override
  Future<List<PostModel>> getAllPosts({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  }) async {
    try {
      final queryParams = <String>[];
      if (postType != null && postType.isNotEmpty) queryParams.add('type=$postType');
      if (category != null && category.isNotEmpty) queryParams.add('category=$category');
      if (country != null && country.isNotEmpty) queryParams.add('country=$country');
      if (state != null && state.isNotEmpty) queryParams.add('state=$state');
      if (city != null && city.isNotEmpty) queryParams.add('city=$city');
      if (area != null && area.isNotEmpty) queryParams.add('area=$area');
      final queryString =
          queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response =
          await apiClient.get('${ApiConstants.allPostsEndpoint}$queryString');
      final List<dynamic> postsJson = response['data'] as List<dynamic>;
      return postsJson
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get posts: $e');
    }
  }

  @override
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final response = await apiClient.get(ApiConstants.myPostsEndpoint);
      final List<dynamic> postsJson = response['data'] as List<dynamic>;
      return postsJson
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get user posts: $e');
    }
  }

  @override
  Future<List<SearchResultModel>> searchByImage({
    required String imagePath,
    required String type,
    required String country,
    String? state,
    String? city,
    String? area,
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final fields = <String, String>{
        'type': type,
        'country': country,
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (category != null) 'category': category,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      };
      final response = await apiClient.postMultipart(
        ApiConstants.searchEndpoint,
        filePath: imagePath,
        fields: fields,
      );
      final List<dynamic> resultsJson =
          response['data'] as List<dynamic>? ?? [];
      return resultsJson
          .map((json) =>
              SearchResultModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to search by image: $e');
    }
  }

  @override
  Future<PostModel> updatePost(Post post) async {
    try {
      final postModel = post is PostModel ? post : PostModel.fromEntity(post);
      final response = await apiClient.put(
        '${ApiConstants.postDetailEndpoint}/${postModel.id}',
        body: postModel.toJson(),
      );
      final data = response['data'];
      if (data == null) return postModel;
      return PostModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to update post: $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await apiClient.delete('${ApiConstants.postDetailEndpoint}/$postId');
    } catch (e) {
      throw ServerException('Failed to delete post: $e');
    }
  }

  @override
  Future<void> updatePostStatus(String postId, String status) async {
    try {
      await apiClient.patch(
        '${ApiConstants.postDetailEndpoint}/$postId/status',
        body: {'status': status},
      );
    } catch (e) {
      throw ServerException('Failed to update post status: $e');
    }
  }

  // ─── Secure Feed Methods ──────────────────────────────────────────────────

  @override
  Future<List<FeedPost>> getPublicFeed({
    String? type,
    String? category,
    String? country,
    String? city,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String>['limit=$limit', 'offset=$offset'];
      if (type != null && type.isNotEmpty) queryParams.add('type=$type');
      if (category != null && category.isNotEmpty)
        queryParams.add('category=$category');
      if (country != null && country.isNotEmpty)
        queryParams.add('country=$country');
      if (city != null && city.isNotEmpty) queryParams.add('city=$city');
      final queryString = '?${queryParams.join('&')}';
      final response = await apiClient
          .get('${ApiConstants.publicFeedEndpoint}$queryString');
      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => FeedPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load feed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVerificationQuestions(
      String postId) async {
    try {
      final response = await apiClient
          .get('${ApiConstants.postDetailEndpoint}/$postId/questions');
      final data = response['data'];
      if (data == null) return [];
      return (data as List<dynamic>)
          .map((q) => q as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw ServerException('Failed to get verification questions: $e');
    }
  }

  @override
  Future<void> updateVerificationQuestions(
      String postId, List<Map<String, dynamic>> questions) async {
    try {
      await apiClient.put(
        '${ApiConstants.postDetailEndpoint}/$postId/questions',
        body: {'questions': questions},
      );
    } catch (e) {
      throw ServerException('Failed to update verification questions: $e');
    }
  }

  @override
  Future<void> sendClaimRequest({
    required String receiverId,
    required String postId,
    String? introMessage,
    List<Map<String, dynamic>>? verificationAnswers,
  }) async {
    try {
      await apiClient.post(
        ApiConstants.sendContactRequestEndpoint,
        body: {
          'receiver_id': receiverId,
          'post_id': postId,
          if (introMessage != null && introMessage.isNotEmpty)
            'intro_message': introMessage,
          if (verificationAnswers != null && verificationAnswers.isNotEmpty)
            'verification_answers': verificationAnswers,
        },
      );
    } catch (e) {
      throw ServerException('Failed to send claim request: $e');
    }
  }
}
