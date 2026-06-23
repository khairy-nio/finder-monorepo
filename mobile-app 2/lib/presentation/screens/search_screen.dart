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
                if (searchProvider.isSearching)
                  const Center(child: CircularProgressIndicator())
                else if (searchProvider.errorMessage != null)
                  _buildError(searchProvider)
                else if (searchProvider.searchResults.isNotEmpty)
                  _buildResults(searchProvider),
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
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: AppColors.grey),
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

  Widget _buildError(SearchProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.searchResults.length} matches found',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...provider.searchResults.map((result) {
          return SearchResultCard(searchResult: result);
        }),
      ],
    );
  }
}
