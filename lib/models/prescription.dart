import '../core/constants/app_constants.dart';

class Prescription {
  final String id;
  final String patientId;
  final String doctorId;
  final String? appointmentId;
  final String? diagnosis;
  final String? notes;
  final PrescriptionStatus status;
  final DateTime issuedDate;
  final DateTime? validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? doctorName;
  final String? doctorSpecialty;
  final List<PrescriptionItem>? items;

  const Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    this.diagnosis,
    this.notes,
    this.status = PrescriptionStatus.active,
    required this.issuedDate,
    this.validUntil,
    required this.createdAt,
    required this.updatedAt,
    this.doctorName,
    this.doctorSpecialty,
    this.items,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctors'] as Map<String, dynamic>?;
    final doctorProfile = doctor?['profiles'] as Map<String, dynamic>?;
    final itemsJson = json['prescription_items'] as List<dynamic>?;

    return Prescription(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      diagnosis: json['diagnosis'] as String?,
      notes: json['notes'] as String?,
      status: PrescriptionStatus.fromString(json['status'] as String? ?? 'active'),
      issuedDate: DateTime.parse(json['issued_date'] as String),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      doctorName: doctorProfile?['full_name'] as String?,
      doctorSpecialty: doctor?['specialty'] as String?,
      items: itemsJson?.map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (notes != null) 'notes': notes,
      'status': status.value,
      'issued_date': issuedDate.toIso8601String().split('T').first,
      if (validUntil != null)
        'valid_until': validUntil!.toIso8601String().split('T').first,
    };
  }
}

class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int? durationDays;
  final String? instructions;
  final int? quantity;
  final int? remaining;
  final DateTime createdAt;

  const PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    this.durationDays,
    this.instructions,
    this.quantity,
    this.remaining,
    required this.createdAt,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] as String,
      prescriptionId: json['prescription_id'] as String,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      durationDays: json['duration_days'] as int?,
      instructions: json['instructions'] as String?,
      quantity: json['quantity'] as int?,
      remaining: json['remaining'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescription_id': prescriptionId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      if (durationDays != null) 'duration_days': durationDays,
      if (instructions != null) 'instructions': instructions,
      if (quantity != null) 'quantity': quantity,
      if (remaining != null) 'remaining': remaining,
    };
  }
}
