import 'api_constants.dart';

class ApiEndpoints {
  // Maintain compatibility while delegating to ApiConstants.
  static String get baseUrl => ApiConstants.baseUrl;

  static String get health => ApiConstants.healthEndpoint;

  // Legacy helpers kept for older code paths.
  static String get createPostWithMatching => ApiConstants.createPostEndpoint;
  static String get getPosts => ApiConstants.allPostsEndpoint;
  static String getPostById(String id) => '${ApiConstants.postDetailEndpoint}/$id';
}
