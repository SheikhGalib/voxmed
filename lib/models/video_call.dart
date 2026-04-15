/// Status of a video call session.
enum VideoCallStatus {
  pending,
  ringing,
  inProgress,
  completed,
  cancelled,
  missed;

  String get value {
    switch (this) {
      case VideoCallStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  static VideoCallStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return VideoCallStatus.inProgress;
      default:
        return VideoCallStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => VideoCallStatus.pending,
        );
    }
  }
}

/// Represents a video call room tied to an appointment.
class VideoCall {
  final String id;
  final String appointmentId;
  final String roomId;
  final String patientId;
  final String doctorId;
  final VideoCallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? patientName;
  final String? doctorName;

  const VideoCall({
    required this.id,
    required this.appointmentId,
    required this.roomId,
    required this.patientId,
    required this.doctorId,
    this.status = VideoCallStatus.pending,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.doctorName,
  });

  factory VideoCall.fromJson(Map<String, dynamic> json) {
    final patient = json['profiles'] as Map<String, dynamic>?;
    final doctor = json['doctors'] as Map<String, dynamic>?;
    final doctorProfile = doctor?['profiles'] as Map<String, dynamic>?;

    return VideoCall(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      roomId: json['room_id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      status: VideoCallStatus.fromString(json['status'] as String? ?? 'pending'),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      patientName: patient?['full_name'] as String?,
      doctorName: doctorProfile?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'room_id': roomId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': status.value,
      if (startedAt != null) 'started_at': startedAt!.toUtc().toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toUtc().toIso8601String(),
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    };
  }

  /// Whether the call can be joined.
  bool get isJoinable =>
      status == VideoCallStatus.pending || status == VideoCallStatus.ringing;
}
