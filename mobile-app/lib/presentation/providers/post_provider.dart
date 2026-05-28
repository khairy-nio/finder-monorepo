import 'package:flutter/foundation.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_all_posts.dart';
import '../../core/errors/failures.dart';

/// Provider for managing posts state
class PostProvider with ChangeNotifier {
  final GetAllPostsUseCase getAllPostsUseCase;

  PostProvider({required this.getAllPostsUseCase});

  // State
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasActiveFilters = false;
  Map<String, String>? _activeFilters; // persists filter selections across refreshes

  // Getters
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveFilters => _hasActiveFilters;
  Map<String, String>? get activeFilters => _activeFilters;

  // Load all posts
  Future<void> loadPosts({
    String? postType,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    
    // Check if any filter is actually active
    _hasActiveFilters = (postType != null && postType.isNotEmpty) ||
                        (category != null && category.isNotEmpty && category != 'All Categories') ||
                        (country != null && country.isNotEmpty) ||
                        (state != null && state.isNotEmpty) ||
                        (city != null && city.isNotEmpty) ||
                        (area != null && area.isNotEmpty);

    notifyListeners();

    final result = await getAllPostsUseCase(
      postType: postType,
      category: category == 'All Categories' ? null : category,
      country: country,
      state: state,
      city: city,
      area: area,
    );

    result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (posts) {
        _isLoading = false;
        _posts = posts;
        notifyListeners();
      },
    );
  }
  // Apply filters from the filter screen — persists the raw selections
  Future<void> applyFilters({
    required Map<String, String> filters,
    String? category,
    String? country,
    String? state,
    String? city,
    String? area,
  }) async {
    _activeFilters = filters;
    await loadPosts(
      category: category,
      country: country,
      state: state,
      city: city,
      area: area,
    );
  }

  // Re-apply last used filters (called on pull-to-refresh)
  Future<void> refresh() async {
    if (_activeFilters != null) {
      final f = _activeFilters!;
      await loadPosts(
        category: f['category'] == 'All' ? null : f['category'],
        country: f['country'],
        state: f['state'],
        city: f['city'],
        area: f['area'],
      );
    } else {
      await loadPosts();
    }
  }


  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Unexpected error occurred.';
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
