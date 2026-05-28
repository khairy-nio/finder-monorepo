/// Post Entity - Domain Layer
class Post {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String postType; // 'lost' or 'found'
  final String imageUrl;
  final String country;
  final String? state;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? ownerName; // Added ownerName
  final String status; // 'active', 'matched', 'resolved', 'closed'
  final String moderationStatus; // 'visible', 'hidden', 'removed'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.postType,
    required this.imageUrl,
    required this.country,
    this.state,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.location,
    this.ownerName,
    this.status = 'active',
    this.moderationStatus = 'visible',
    required this.createdAt,
    this.updatedAt,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? postType,
    String? imageUrl,
    String? country,
    String? state,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    String? location,
    String? ownerName,
    String? status,
    String? moderationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      postType: postType ?? this.postType,
      imageUrl: imageUrl ?? this.imageUrl,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
