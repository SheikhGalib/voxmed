class Review {
  final String id;
  final String patientId;
  final String doctorId;
  final String? appointmentId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Joined data
  final String? patientName;
  final String? patientAvatarUrl;

  const Review({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.patientName,
    this.patientAvatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final patient = json['profiles'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientName: patient?['full_name'] as String?,
      patientAvatarUrl: patient?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}
