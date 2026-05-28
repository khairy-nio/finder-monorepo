import '../entities/post.dart';
import '../repositories/post_repository.dart';
import '../../core/errors/failures.dart';

/// Use Case: Get all posts
class GetAllPostsUseCase {
  final PostRepository repository;

  GetAllPostsUseCase(this.repository);

  Future<Either<Failure, List<Post>>> call({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  }) async {
    return await repository.getAllPosts(
      postType: postType,
      category: category,
      country: country,
      state: state,
      city: city,
      area: area,
    );
  }
}
