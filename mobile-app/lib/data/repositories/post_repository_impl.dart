import '../../domain/entities/post.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/post_repository.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../datasources/post_remote_data_source.dart';
import '../models/post_model.dart';

/// Post Repository Implementation - Data Layer
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      final post = await remoteDataSource.createPost(
        title: title,
        description: description,
        category: category,
        postType: postType,
        imagePath: imagePath,
        country: country,
        state: state,
        city: city,
        area: area,
        latitude: latitude,
        longitude: longitude,
        location: location,
      );
      return Either.right(post);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> getPostById(String postId) async {
    try {
      final post = await remoteDataSource.getPostById(postId);
      return Either.right(post);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getAllPosts({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  }) async {
    try {
      final posts = await remoteDataSource.getAllPosts(
        postType: postType,
        category: category,
        country: country,
        state: state,
        city: city,
        area: area,
      );
      return Either.right(posts);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getUserPosts(String userId) async {
    try {
      final posts = await remoteDataSource.getUserPosts(userId);
      return Either.right(posts);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
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
  }) async {
    try {
      final results = await remoteDataSource.searchByImage(
        imagePath: imagePath,
        type: type,
        country: country,
        state: state,
        city: city,
        area: area,
        category: category,
        latitude: latitude,
        longitude: longitude,
      );
      return Either.right(results);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> updatePost(Post post) async {
    try {
      final updatedPost = await remoteDataSource.updatePost(
        PostModel.fromEntity(post),
      );
      return Either.right(updatedPost);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure('Unexpected error: $e'));
    }
  }
}
