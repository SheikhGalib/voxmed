import '../core/constants/app_constants.dart';

/// A patient's medication reminder schedule for one prescription item.
class MedicationSchedule {
  final String id;
  final String patientId;
  final String? prescriptionItemId;
  final String medicationName;
  final String dosage;
  final String frequency;

  /// Times of day as HH:MM strings (24-hour). e.g. ['08:00', '14:00', '20:00']
  final List<String> timesOfDay;

  /// ISO weekday numbers: 1=Mon … 7=Sun. null = every day.
  final List<int>? daysOfWeek;

  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationSchedule({
    required this.id,
    required this.patientId,
    this.prescriptionItemId,
    required this.medicationName,
    required this.dosage,
    this.frequency = 'daily',
    required this.timesOfDay,
    this.daysOfWeek,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      prescriptionItemId: json['prescription_item_id'] as String?,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String? ?? 'daily',
      timesOfDay: List<String>.from(json['times_of_day'] as List? ?? ['08:00']),
      daysOfWeek: json['days_of_week'] == null
          ? null
          : List<int>.from(json['days_of_week'] as List),
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    if (prescriptionItemId != null) 'prescription_item_id': prescriptionItemId,
    'medication_name': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'times_of_day': timesOfDay,
    if (daysOfWeek != null) 'days_of_week': daysOfWeek,
    'is_active': isActive,
    if (notes != null) 'notes': notes,
  };

  MedicationSchedule copyWith({
    String? medicationName,
    String? dosage,
    String? frequency,
    List<String>? timesOfDay,
    List<int>? daysOfWeek,
    bool? isActive,
    String? notes,
  }) {
    return MedicationSchedule(
      id: id,
      patientId: patientId,
      prescriptionItemId: prescriptionItemId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Returns all scheduled [DateTime]s for today.
  List<DateTime> todayDoseTimes() {
    final now = DateTime.now();
    final today = now.weekday; // 1=Mon … 7=Sun

    // Skip if today isn't in the active days list.
    if (daysOfWeek != null && !daysOfWeek!.contains(today)) return [];

    return timesOfDay.map((t) {
      final parts = t.split(':');
      final h = int.tryParse(parts[0]) ?? 8;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return DateTime(now.year, now.month, now.day, h, m);
    }).toList();
  }

  /// Returns any dose time that passed in the last [windowMinutes] minutes
  /// and has not been taken yet (caller must verify against adherence logs).
  List<DateTime> recentlyDueTimes({int windowMinutes = 120}) {
    final now = DateTime.now();
    return todayDoseTimes()
        .where(
          (t) =>
              t.isBefore(now) && now.difference(t).inMinutes <= windowMinutes,
        )
        .toList();
  }

  static String formatDoseTimeLabel(DateTime time) {
    final local = time.toLocal();
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class MedicationAdherenceEntry {
  final String id;
  final String? scheduleId;
  final String? prescriptionItemId;
  final String medicationName;
  final String? dosage;
  final DateTime scheduledTime;
  final DateTime? responseTime;
  final AdherenceStatus status;
  final bool isDerived;

  const MedicationAdherenceEntry({
    required this.id,
    this.scheduleId,
    this.prescriptionItemId,
    required this.medicationName,
    this.dosage,
    required this.scheduledTime,
    this.responseTime,
    required this.status,
    this.isDerived = false,
  });

  factory MedicationAdherenceEntry.fromJson(Map<String, dynamic> json) {
    final schedule = json['medication_schedules'] as Map<String, dynamic>?;
    final item = json['prescription_items'] as Map<String, dynamic>?;

    return MedicationAdherenceEntry(
      id: json['id'] as String? ?? '',
      scheduleId: json['schedule_id'] as String?,
      prescriptionItemId: json['prescription_item_id'] as String?,
      medicationName:
          json['medication_name'] as String? ??
          schedule?['medication_name'] as String? ??
          item?['medication_name'] as String? ??
          'Medication',
      dosage:
          schedule?['dosage'] as String? ??
          item?['dosage'] as String? ??
          json['dosage'] as String?,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String).toLocal(),
      responseTime: json['response_time'] == null
          ? null
          : DateTime.parse(json['response_time'] as String).toLocal(),
      status: AdherenceStatus.fromString(json['status'] as String? ?? 'missed'),
    );
  }

  factory MedicationAdherenceEntry.derivedMissed({
    required MedicationSchedule schedule,
    required DateTime scheduledTime,
  }) {
    return MedicationAdherenceEntry(
      id: 'derived:${schedule.id}:${scheduledTime.toUtc().toIso8601String()}',
      scheduleId: schedule.id,
      prescriptionItemId: schedule.prescriptionItemId,
      medicationName: schedule.medicationName,
      dosage: schedule.dosage,
      scheduledTime: scheduledTime,
      status: AdherenceStatus.missed,
      isDerived: true,
    );
  }

  String get timeLabel => MedicationSchedule.formatDoseTimeLabel(scheduledTime);

  String get statusLabel {
    switch (status) {
      case AdherenceStatus.taken:
        return 'Taken';
      case AdherenceStatus.missed:
        return 'Missed';
      case AdherenceStatus.skipped:
        return 'Skipped';
      case AdherenceStatus.pending:
        return 'Pending';
    }
  }
}
