import '../../domain/entities/post.dart';
import '../../core/constants/api_constants.dart';


/// Post Model - Data Layer (extends Entity)
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.category,
    required super.postType,
    required super.imageUrl,
    required super.country,
    super.state,
    super.city,
    super.area,
    super.latitude,
    super.longitude,
    super.location,
    super.ownerName,
    super.status = 'active',
    super.moderationStatus = 'visible',
    required super.createdAt,
    super.updatedAt,
  });

  /// From JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      postType: json['post_type'] as String? ?? 'lost',
      imageUrl: _formatImageUrl(json['image_url'] as String?),
      country: json['country'] as String? ?? '',
      state: json['state'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      location: json['location'] as String? ?? 
          [json['area'], json['city'], json['state'], json['country']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(', '),
      ownerName: (json['owner'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown User',
      status: json['status'] as String? ?? 'active',
      moderationStatus: json['moderation_status'] as String? ?? 'visible',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static String _formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    // Remove leading slash if present to avoid double slashes
    final path = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
    return '${ApiConstants.baseUrl}/$path';
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'post_type': postType,
      'image_url': imageUrl,
      'country': country,
      'state': state,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'ownerName': ownerName,
      'status': status,
      'moderation_status': moderationStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// From Entity
  factory PostModel.fromEntity(Post post) {
    return PostModel(
      id: post.id,
      userId: post.userId,
      title: post.title,
      description: post.description,
      category: post.category,
      postType: post.postType,
      imageUrl: post.imageUrl,
      country: post.country,
      state: post.state,
      city: post.city,
      area: post.area,
      latitude: post.latitude,
      longitude: post.longitude,
      location: post.location,
      ownerName: post.ownerName,
      status: post.status,
      moderationStatus: post.moderationStatus,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    );
  }
}
