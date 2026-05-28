import '../entities/post.dart';
import '../repositories/post_repository.dart';
import '../../core/errors/failures.dart';

/// Use Case: Create a new post (Lost or Found)
class CreatePostUseCase {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  Future<Either<Failure, Post>> call({
    required String title,
    required String description,
    required String category,
    required String postType,
    required String imagePath,
    required String country,
    String? state,
    String? city,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    return await repository.createPost(
      title: title,
      description: description,
      category: category,
      postType: postType,
      imagePath: imagePath,
      country: country,
      state: state,
      city: city,
      latitude: latitude,
      longitude: longitude,
      location: location,
    );
  }
}
