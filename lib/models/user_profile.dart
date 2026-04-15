import '../core/constants/app_constants.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? avatarUrl;
  final Map<String, dynamic>? emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.avatarUrl,
    this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'patient'),
      fullName: json['full_name'] as String? ?? 'User',
      email: json['email'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      emergencyContact: json['emergency_contact'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'full_name': fullName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (address != null) 'address': address,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
    };
  }

  /// For profile updates — only mutable fields.
  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (address != null) 'address': address,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? avatarUrl,
    Map<String, dynamic>? emergencyContact,
  }) {
    return UserProfile(
      id: id,
      role: role,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
