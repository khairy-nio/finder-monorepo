import '../entities/post.dart';
import '../entities/search_result.dart';
import '../../core/errors/failures.dart';

/// Post Repository Interface - Domain Layer
abstract class PostRepository {
  /// Create a new post
  Future<Either<Failure, Post>> createPost({
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

  /// Get post by ID
  Future<Either<Failure, Post>> getPostById(String postId);

  /// Get all posts
  Future<Either<Failure, List<Post>>> getAllPosts({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  });

  /// Get user's posts
  Future<Either<Failure, List<Post>>> getUserPosts(String userId);

  /// Search posts by image
  Future<Either<Failure, List<SearchResult>>> searchByImage(
    String imagePath, {
    required String type,
    required String country,
    String? state,
    String? city,
    String? area,
    String? category,
    double? latitude,
    double? longitude,
  });

  /// Update post
  Future<Either<Failure, Post>> updatePost(Post post);

  /// Delete post
  Future<Either<Failure, void>> deletePost(String postId);
}

/// Either class for error handling
class Either<L, R> {
  final L? _left;
  final R? _right;

  Either.left(L left) : _left = left, _right = null;

  Either.right(R right) : _left = null, _right = right;

  bool get isLeft => _left != null;
  bool get isRight => _right != null;

  L get left => _left as L;
  R get right => _right as R;

  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    if (isLeft) {
      return leftFn(_left as L);
    } else {
      return rightFn(_right as R);
    }
  }
}
