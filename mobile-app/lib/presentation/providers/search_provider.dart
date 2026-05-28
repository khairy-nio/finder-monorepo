import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_by_image.dart';
import '../../core/errors/failures.dart';

/// Provider for search functionality
class SearchProvider with ChangeNotifier {
  final SearchByImageUseCase searchByImageUseCase;

  SearchProvider({required this.searchByImageUseCase});

  // State
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  XFile? _selectedImage;

  // Getters
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  XFile? get selectedImage => _selectedImage;

  // Set selected image
  void setSelectedImage(XFile? image) {
    _selectedImage = image;
    notifyListeners();
  }

  // Search by image
  Future<void> searchByImage({
    required String imagePath,
    required String type,
    required String country,
    required String city,
    String? category,
    String? state,
    double? latitude,
    double? longitude,
  }) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    final result = await searchByImageUseCase(
      imagePath: imagePath,
      type: type,
      country: country,
      city: city,
      category: category,
      state: state,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      (failure) {
        _isSearching = false;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (results) {
        _isSearching = false;
        _searchResults = results;
        notifyListeners();
      },
    );
  }

  // Clear search results
  void clearResults() {
    _searchResults = [];
    _selectedImage = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Unexpected error occurred.';
    }
  }
}
