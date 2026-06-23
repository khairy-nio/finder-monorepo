import 'package:flutter/material.dart';
import '../../domain/entities/search_result.dart';
import '../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Search Result Card Widget - Displays a single search result with similarity score
class SearchResultCard extends StatelessWidget {
  final SearchResult searchResult;

  const SearchResultCard({super.key, required this.searchResult});

  @override
  Widget build(BuildContext context) {
    final post = searchResult.post;
    final similarityPercentage = (searchResult.similarity * 100)
        .toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/post-detail', arguments: {
            'postId': post.id,
            'userId': post.userId,
            'title': post.title,
            'category': post.category,
            'timeAgo': 'Recently', // Simplified since we don't have _getTimeAgo here easily
            'posterName': 'User',
            'isVerified': false,
            'dateLost': '${post.createdAt.month}/${post.createdAt.day}/${post.createdAt.year}',
            'refId': '#${post.id.substring(0, 8)}',
            'description': post.description,
            'location': post.location ?? 'Location Unknown',
            'distance': 'Unknown distance',
            'imageUrl': post.imageUrl,
            'status': post.postType,
            'matchPercentage': (searchResult.similarity * 100).toInt(),
            'latitude': post.latitude ?? 0.0,
            'longitude': post.longitude ?? 0.0,
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.greyLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.greyLight,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Similarity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSimilarityColor(searchResult.similarity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$similarityPercentage% Match',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Post Type & Category
                    Row(
                      children: [
                        _buildPostTypeBadge(post.postType),
                        const SizedBox(width: 8),
                        Text(
                          post.category,
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) {
      return AppColors.success;
    } else if (similarity >= 0.6) {
      return AppColors.warning;
    } else {
      return AppColors.grey;
    }
  }

  Widget _buildPostTypeBadge(String postType) {
    final isLost = postType.toLowerCase() == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLost ? AppColors.lostColor : AppColors.foundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        postType.toUpperCase(),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
