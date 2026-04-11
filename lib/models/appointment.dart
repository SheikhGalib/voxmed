import '../core/constants/app_constants.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String? hospitalId;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? reason;
  final String? notes;
  final String? rescheduledFrom;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorAvatarUrl;
  final String? patientName;
  final String? hospitalName;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.hospitalId,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    this.status = AppointmentStatus.scheduled,
    this.type = AppointmentType.inPerson,
    this.reason,
    this.notes,
    this.rescheduledFrom,
    required this.createdAt,
    required this.updatedAt,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorAvatarUrl,
    this.patientName,
    this.hospitalName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Handle joined doctor data
    final doctor = json['doctors'] as Map<String, dynamic>?;
    final doctorProfile = doctor?['profiles'] as Map<String, dynamic>?;
    final patient = json['profiles'] as Map<String, dynamic>?;
    final hospital = json['hospitals'] as Map<String, dynamic>?;

    return Appointment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      hospitalId: json['hospital_id'] as String?,
      scheduledStartAt: DateTime.parse(json['scheduled_start_at'] as String),
      scheduledEndAt: DateTime.parse(json['scheduled_end_at'] as String),
      status: AppointmentStatus.fromString(json['status'] as String? ?? 'scheduled'),
      type: AppointmentType.fromString(json['type'] as String? ?? 'in_person'),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      rescheduledFrom: json['rescheduled_from'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      doctorName: doctorProfile?['full_name'] as String?,
      doctorSpecialty: doctor?['specialty'] as String?,
      doctorAvatarUrl: doctorProfile?['avatar_url'] as String?,
      patientName: patient?['full_name'] as String?,
      hospitalName: hospital?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      if (hospitalId != null) 'hospital_id': hospitalId,
      'scheduled_start_at': scheduledStartAt.toUtc().toIso8601String(),
      'scheduled_end_at': scheduledEndAt.toUtc().toIso8601String(),
      'status': status.value,
      'type': type.value,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (rescheduledFrom != null) 'rescheduled_from': rescheduledFrom,
    };
  }

  /// Whether this appointment is upcoming (not completed/cancelled).
  bool get isUpcoming =>
      status == AppointmentStatus.scheduled ||
      status == AppointmentStatus.confirmed;
}
