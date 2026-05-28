import '../entities/search_result.dart';
import '../repositories/post_repository.dart';
import '../../core/errors/failures.dart';

/// Use Case: Search posts by uploading an image
class SearchByImageUseCase {
  final PostRepository repository;

  SearchByImageUseCase(this.repository);

  Future<Either<Failure, List<SearchResult>>> call({
    required String imagePath,
    required String type,
    required String country,
    required String city,
    String? category,
    String? state,
    double? latitude,
    double? longitude,
  }) async {
    return await repository.searchByImage(
      imagePath,
      type: type,
      country: country,
      city: city,
      category: category,
      state: state,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
