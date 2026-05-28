import 'post.dart';

/// Search Result Entity - Domain Layer
class SearchResult {
  final Post post;
  final double similarity; // Cosine similarity score (0-1)

  const SearchResult({required this.post, required this.similarity});
}
