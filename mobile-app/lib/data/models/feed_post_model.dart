/// Feed Post Model — safe public DTO with no sensitive fields.
/// Mirrors the backend PUBLIC_FEED_ATTRIBUTES list.
/// ❌ No imageUrl  ❌ No latitude/longitude  ❌ No verificationQuestions
class FeedPost {
  final String id;
  final String userId;
  final String postType; // 'lost' | 'found'
  final String title;
  final String? description;
  final String? category;
  final String country;
  final String? state;
  final String? city;
  final String? area;
  final String status;
  final String moderationStatus;
  final DateTime createdAt;
  final bool ownerVerified;

  const FeedPost({
    required this.id,
    required this.userId,
    required this.postType,
    required this.title,
    this.description,
    this.category,
    required this.country,
    this.state,
    this.city,
    this.area,
    required this.status,
    required this.moderationStatus,
    required this.createdAt,
    this.ownerVerified = false,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return FeedPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postType: json['post_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      country: json['country'] as String? ?? '',
      state: json['state'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      status: json['status'] as String? ?? 'active',
      moderationStatus: json['moderation_status'] as String? ?? 'visible',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      ownerVerified: owner?['verified'] as bool? ?? false,
    );
  }

  /// Rough location string for display (city or area, no exact coordinates).
  String get roughLocation {
    final parts = <String>[
      if (area != null && area!.isNotEmpty) area!,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    if (parts.isEmpty) return country;
    return parts.first; // Show most specific available
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  bool get isLost => postType.toLowerCase() == 'lost';
}
