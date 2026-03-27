import '../core/constants/app_constants.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String? doctorId;
  final String? appointmentId;
  final RecordType recordType;
  final String title;
  final String? description;
  final Map<String, dynamic>? data;
  final String? fileUrl;
  final bool ocrExtracted;
  final DateTime? recordDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalRecord({
    required this.id,
    required this.patientId,
    this.doctorId,
    this.appointmentId,
    required this.recordType,
    required this.title,
    this.description,
    this.data,
    this.fileUrl,
    this.ocrExtracted = false,
    this.recordDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String?,
      appointmentId: json['appointment_id'] as String?,
      recordType: RecordType.fromString(json['record_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      fileUrl: json['file_url'] as String?,
      ocrExtracted: json['ocr_extracted'] as bool? ?? false,
      recordDate: json['record_date'] != null
          ? DateTime.parse(json['record_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'record_type': recordType.value,
      'title': title,
      if (description != null) 'description': description,
      if (data != null) 'data': data,
      if (fileUrl != null) 'file_url': fileUrl,
      'ocr_extracted': ocrExtracted,
      if (recordDate != null)
        'record_date': recordDate!.toIso8601String().split('T').first,
    };
  }
}
