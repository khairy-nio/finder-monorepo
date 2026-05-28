import '../../domain/entities/user.dart';

/// UserModel — Data Layer
/// Serializes/deserializes the JSON from GET /user/me and POST /user/login.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firebaseUid,
    required super.email,
    required super.name,
    required super.role,
    required super.status,
    required super.verified,
    required super.trustScore,
    required super.verificationStatus,
    super.phoneNumber,
    super.country,
    super.state,
    super.city,
    super.area,
    super.profileImageUrl,
    super.selfieImageUrl,
    super.nationalId,
    super.idImageUrl,
    super.verificationLocation,
    super.verificationNotes,
    super.bio,
    super.recoveryPoints = 0,
    super.verificationSubmittedAt,
    super.verificationReviewedAt,
    required super.createdAt,
  });


  /// Parses the JSON object returned by the backend /user/me endpoint.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String? ?? '',
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      verified: (json['verified'] as bool?) ?? false,
      trustScore: ((json['trust_score'] as num?) ?? 0.0).toDouble(),
      verificationStatus:
          json['verification_status'] as String? ?? 'not_submitted',
      phoneNumber: json['phone_number'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      selfieImageUrl: json['selfie_image_url'] as String?,
      nationalId: json['national_id'] as String?,
      idImageUrl: json['id_image_url'] as String?,
      verificationLocation: json['verification_location'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      bio: json['bio'] as String?,
      recoveryPoints: (json['recovery_points'] as num?)?.toInt() ?? 0,
      verificationSubmittedAt:
          json['verification_submitted_at'] != null
              ? DateTime.tryParse(
                  json['verification_submitted_at'] as String,
                )
              : null,
      verificationReviewedAt:
          json['verification_reviewed_at'] != null
              ? DateTime.tryParse(
                  json['verification_reviewed_at'] as String,
                )
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts to JSON (for local caching or update calls).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'verified': verified,
      'trust_score': trustScore,
      'verification_status': verificationStatus,
      'phone_number': phoneNumber,
      'country': country,
      'state': state,
      'city': city,
      'area': area,
      'profile_image_url': profileImageUrl,
      'selfie_image_url': selfieImageUrl,
      'national_id': nationalId,
      'id_image_url': idImageUrl,
      'verification_location': verificationLocation,
      'verification_notes': verificationNotes,
      'bio': bio,
      'recovery_points': recoveryPoints,
      'verification_submitted_at':
          verificationSubmittedAt?.toIso8601String(),

      'verification_reviewed_at': verificationReviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain entity to a model (for update flows).
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      name: user.name,
      role: user.role,
      status: user.status,
      verified: user.verified,
      trustScore: user.trustScore,
      verificationStatus: user.verificationStatus,
      phoneNumber: user.phoneNumber,
      country: user.country,
      state: user.state,
      city: user.city,
      area: user.area,
      profileImageUrl: user.profileImageUrl,
      selfieImageUrl: user.selfieImageUrl,
      nationalId: user.nationalId,
      idImageUrl: user.idImageUrl,
      verificationLocation: user.verificationLocation,
      verificationNotes: user.verificationNotes,
      bio: user.bio,
      recoveryPoints: user.recoveryPoints,
      verificationSubmittedAt: user.verificationSubmittedAt,
      verificationReviewedAt: user.verificationReviewedAt,
      createdAt: user.createdAt,
    );
  }
}

