/// User Entity - Domain Layer
/// Matches the backend /user/me response schema exactly.
class User {
  final String id;
  final String firebaseUid;
  final String email;
  final String name;
  final String role; // 'user' | 'admin'
  final String status; // 'active' | 'suspended' | 'banned'
  final bool verified;
  final double trustScore;
  final String verificationStatus; // 'not_submitted' | 'pending' | 'approved' | 'rejected'
  final String? phoneNumber;
  final String? country;
  final String? state;
  final String? city;
  final String? area;
  final String? profileImageUrl;
  final String? selfieImageUrl;
  final String? nationalId;
  final String? idImageUrl;
  final String? verificationLocation;
  final String? verificationNotes;
  final String? bio;
  final int recoveryPoints;
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationReviewedAt;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin';

  const User({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.role,
    this.status = 'active',
    required this.verified,
    required this.trustScore,
    required this.verificationStatus,
    this.phoneNumber,
    this.country,
    this.state,
    this.city,
    this.area,
    this.profileImageUrl,
    this.selfieImageUrl,
    this.nationalId,
    this.idImageUrl,
    this.verificationLocation,
    this.verificationNotes,
    this.bio,
    this.recoveryPoints = 0,
    this.verificationSubmittedAt,
    this.verificationReviewedAt,
    required this.createdAt,
  });


  User copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? name,
    String? role,
    String? status,
    bool? verified,
    double? trustScore,
    String? verificationStatus,
    String? phoneNumber,
    String? country,
    String? state,
    String? city,
    String? area,
    String? profileImageUrl,
    String? selfieImageUrl,
    String? nationalId,
    String? idImageUrl,
    String? verificationLocation,
    String? verificationNotes,
    String? bio,
    int? recoveryPoints,
    DateTime? verificationSubmittedAt,
    DateTime? verificationReviewedAt,
    DateTime? createdAt,
  }) {

    return User(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      trustScore: trustScore ?? this.trustScore,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      area: area ?? this.area,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      nationalId: nationalId ?? this.nationalId,
      idImageUrl: idImageUrl ?? this.idImageUrl,
      verificationLocation: verificationLocation ?? this.verificationLocation,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      bio: bio ?? this.bio,
      recoveryPoints: recoveryPoints ?? this.recoveryPoints,
      verificationSubmittedAt:
          verificationSubmittedAt ?? this.verificationSubmittedAt,
      verificationReviewedAt:
          verificationReviewedAt ?? this.verificationReviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

