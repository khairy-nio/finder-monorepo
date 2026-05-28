import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Post Card Widget - Displays a single post in suggested posts style
class PostCard extends StatelessWidget {
  final Post post;
  final Color? backgroundColor;

  const PostCard({super.key, required this.post, this.backgroundColor});

  String _getTimeAgo() {
    final difference = DateTime.now().difference(post.createdAt);

    if (difference.inHours < 24) {
      if (difference.inHours < 1) {
        return 'Found ${difference.inMinutes}m ago';
      }
      return 'Found ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Found Yesterday';
    } else if (difference.inDays < 7) {
      return 'Found ${difference.inDays} days ago';
    } else {
      return 'Found ${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  String _getBadgeText() {
    if (post.postType.toLowerCase() == 'lost') {
      return 'Lost Item';
    }
    return _getTimeAgo();
  }

  Color _getBadgeColor() {
    if (post.postType.toLowerCase() == 'lost') {
      return const Color(0xFF0A3D91); // Blue for lost items
    }
    return const Color(0xFF0A3D91); // Blue for found items
  }

  Color _getBadgeTextColor() {
    return Colors.white; // White text for both lost and found
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/post-detail',
          arguments: {
            'postId': post.id,
            'userId': post.userId,
            'title': post.title,
            'category': post.category,
            'timeAgo': _getTimeAgo(),
            'posterName': post.ownerName ?? 'Unknown User',
            'isVerified': false,
            'dateLost':
                '${post.createdAt.month}/${post.createdAt.day}/${post.createdAt.year}',
            'refId': '#${post.id.substring(0, 8)}',
            'description': post.description,
            'location': post.location ?? 'Location Unknown',
            'distance': '1.2 km away',
            'imageUrl': post.imageUrl,
            'status': post.postType,
            'matchPercentage': 0,
            // Default coordinates (Central Park, NY)
            'latitude': 40.7829,
            'longitude': -73.9654,
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container with Badge
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: backgroundColor ?? const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0A3D91), width: 2),
            ),
            child: Stack(
              children: [
                // Image
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 280,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 280,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getBadgeText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getBadgeTextColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          // Location
          if (post.location != null && post.location!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    post.location!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
