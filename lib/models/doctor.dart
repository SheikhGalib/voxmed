class Doctor {
  final String id;
  final String profileId;
  final String? hospitalId;
  final String specialty;
  final String? subSpecialty;
  final List<String>? qualifications;
  final int? experienceYears;
  final String? bio;
  final double? consultationFee;
  final int patientsCount;
  final int reviewsCount;
  final double rating;
  final bool isAvailable;
  final String? chamberAddress;
  final String? chamberCity;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data from profiles table (populated via select with join)
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  // Joined data from hospitals table
  final String? hospitalName;

  const Doctor({
    required this.id,
    required this.profileId,
    this.hospitalId,
    required this.specialty,
    this.subSpecialty,
    this.qualifications,
    this.experienceYears,
    this.bio,
    this.consultationFee,
    this.patientsCount = 0,
    this.reviewsCount = 0,
    this.rating = 0,
    this.isAvailable = true,
    this.chamberAddress,
    this.chamberCity,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.avatarUrl,
    this.email,
    this.hospitalName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    final profile = json['profiles'] as Map<String, dynamic>?;
    final hospital = json['hospitals'] as Map<String, dynamic>?;

    return Doctor(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      hospitalId: json['hospital_id'] as String?,
      specialty: json['specialty'] as String,
      subSpecialty: json['sub_specialty'] as String?,
      qualifications: (json['qualifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      experienceYears: json['experience_years'] as int?,
      bio: json['bio'] as String?,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      patientsCount: json['patients_count'] as int? ?? 0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      chamberAddress: json['chamber_address'] as String?,
      chamberCity: json['chamber_city'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      email: profile?['email'] as String?,
      hospitalName: hospital?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      if (hospitalId != null) 'hospital_id': hospitalId,
      'specialty': specialty,
      if (subSpecialty != null) 'sub_specialty': subSpecialty,
      if (qualifications != null) 'qualifications': qualifications,
      if (experienceYears != null) 'experience_years': experienceYears,
      if (bio != null) 'bio': bio,
      if (consultationFee != null) 'consultation_fee': consultationFee,
      'is_available': isAvailable,
      if (chamberAddress != null) 'chamber_address': chamberAddress,
      if (chamberCity != null) 'chamber_city': chamberCity,
    };
  }

  /// Display name: uses joined profile name or fallback.
  String get displayName => fullName ?? 'Dr. Unknown';
}
