import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/search_provider.dart';
import '../widgets/search_result_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_helper.dart';

/// Search Screen - Search for lost items by uploading an image
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.searchByImage)),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.isSearching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3 * value),
                                blurRadius: 20 * value,
                                spreadRadius: 5 * value,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Searching for matches...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Our AI is analyzing your image to find potential matches in the database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image selection area
                _buildImageSelector(context, searchProvider),
                const SizedBox(height: 24),

                // Search button
                if (searchProvider.selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: searchProvider.isSearching
                        ? null
                        : () {
                            // TODO: Replace these with actual values from your UI or user input
                            searchProvider.searchByImage(
                              imagePath: searchProvider.selectedImage!.path,
                              type: 'lost', // or 'found', depending on context
                              country: 'YourCountry', // replace with actual country
                              city: 'YourCity', // replace with actual city
                              // category, state, latitude, longitude can be added if available
                            );
                          },
                    icon: const Icon(Icons.search),
                    label: Text(
                      searchProvider.isSearching
                          ? AppStrings.loading
                          : AppStrings.search,
                    ),
                  ),

                const SizedBox(height: 24),

                // Results
                if (searchProvider.errorMessage != null)
                  _buildError(context, searchProvider)
                else if (searchProvider.searchResults.isNotEmpty)
                  _buildResults(context, searchProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSelector(BuildContext context, SearchProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(provider.selectedImage!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: AppColors.textTertiary),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final image = await ImageHelper.captureFromCamera();
                      if (image != null) {
                        provider.setSelectedImage(image);
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(AppStrings.takePhoto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final image = await ImageHelper.pickFromGallery();
                      if (image != null) {
                        provider.setSelectedImage(image);
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text(AppStrings.chooseFromGallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, SearchProvider provider) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.searchResults.length} Matches Found',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.searchResults.map((result) {
          return SearchResultCard(searchResult: result);
        }),
      ],
    );
  }
}
