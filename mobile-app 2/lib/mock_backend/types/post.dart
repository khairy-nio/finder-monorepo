class PostDto {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String status; // 'active', 'resolved', 'closed'
  final String postType; // 'lost', 'found'
  final String country;
  final String? state;
  final String city;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostDto({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.status,
    required this.postType,
    required this.country,
    this.state,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      imageUrl: json['image_url'],
      status: json['status'],
      postType: json['post_type'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'status': status,
      'post_type': postType,
      'country': country,
      'state': state,
      'city': city,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
