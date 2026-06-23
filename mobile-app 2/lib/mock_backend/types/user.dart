class UserDto {
  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String role; // 'user', 'admin'
  final bool verified;
  final double trustScore;
  final String? nationalId;
  final String? phoneNumber;
  final String? idImageUrl;
  final String verificationStatus; // 'not_submitted', 'pending', 'approved', 'rejected'
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationReviewedAt;
  final String? verificationNotes;
  final DateTime createdAt;

  UserDto({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.role,
    required this.verified,
    required this.trustScore,
    this.nationalId,
    this.phoneNumber,
    this.idImageUrl,
    required this.verificationStatus,
    this.verificationSubmittedAt,
    this.verificationReviewedAt,
    this.verificationNotes,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      verified: json['verified'],
      trustScore: (json['trust_score'] as num).toDouble(),
      nationalId: json['national_id'],
      phoneNumber: json['phone_number'],
      idImageUrl: json['id_image_url'],
      verificationStatus: json['verification_status'],
      verificationSubmittedAt: json['verification_submitted_at'] != null 
          ? DateTime.parse(json['verification_submitted_at']) 
          : null,
      verificationReviewedAt: json['verification_reviewed_at'] != null 
          ? DateTime.parse(json['verification_reviewed_at']) 
          : null,
      verificationNotes: json['verification_notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'name': name,
      'email': email,
      'role': role,
      'verified': verified,
      'trust_score': trustScore,
      'national_id': nationalId,
      'phone_number': phoneNumber,
      'id_image_url': idImageUrl,
      'verification_status': verificationStatus,
      'verification_submitted_at': verificationSubmittedAt?.toIso8601String(),
      'verification_reviewed_at': verificationReviewedAt?.toIso8601String(),
      'verification_notes': verificationNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
