import '../../domain/entities/search_result.dart';
import 'post_model.dart';

/// Search Result Model - Data Layer
class SearchResultModel extends SearchResult {
  const SearchResultModel({required super.post, required super.similarity});

  /// From JSON
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      post: PostModel.fromJson(json['post'] as Map<String, dynamic>),
      similarity: (json['similarity'] as num).toDouble(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'post': PostModel.fromEntity(post).toJson(),
      'similarity': similarity,
    };
  }
}
