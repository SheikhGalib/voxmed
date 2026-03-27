class DoctorSchedule {
  final String id;
  final String doctorId;
  final int dayOfWeek; // 0=Sunday, 6=Saturday
  final String startTime; // HH:mm format
  final String endTime;
  final int slotDurationMinutes;
  final bool isActive;
  final DateTime createdAt;

  const DoctorSchedule({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 30,
    this.isActive = true,
    required this.createdAt,
  });

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_minutes': slotDurationMinutes,
      'is_active': isActive,
    };
  }

  /// Day name from day_of_week index.
  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  String get shortDayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }
}
