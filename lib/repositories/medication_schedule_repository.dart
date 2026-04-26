import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medication_schedule.dart';

class MedicationScheduleRepository {
  // ─────────────────────────── CRUD ────────────────────────────────────────

  Future<List<MedicationSchedule>> listByPatient() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return [];

      final data = await supabase
          .from(Tables.medicationSchedules)
          .select()
          .eq('patient_id', uid)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data)
          .map(MedicationSchedule.fromJson)
          .toList();
    } catch (e) {
      throw AppException(message: 'Failed to load medication schedules: $e');
    }
  }

  Future<MedicationSchedule> create(MedicationSchedule schedule) async {
    try {
      final data = await supabase
          .from(Tables.medicationSchedules)
          .insert(schedule.toJson())
          .select()
          .single();

      return MedicationSchedule.fromJson(data);
    } catch (e) {
      throw AppException(message: 'Failed to create medication schedule: $e');
    }
  }

  Future<MedicationSchedule> update(MedicationSchedule schedule) async {
    try {
      final data = await supabase
          .from(Tables.medicationSchedules)
          .update(schedule.toJson())
          .eq('id', schedule.id)
          .select()
          .single();

      return MedicationSchedule.fromJson(data);
    } catch (e) {
      throw AppException(message: 'Failed to update medication schedule: $e');
    }
  }

  Future<void> delete(String scheduleId) async {
    try {
      await supabase
          .from(Tables.medicationSchedules)
          .delete()
          .eq('id', scheduleId);
    } catch (e) {
      throw AppException(message: 'Failed to delete medication schedule: $e');
    }
  }

  // ─────────────────────────── ADHERENCE LOGGING ───────────────────────────

  /// Log whether the patient took, missed, or skipped a scheduled dose.
  Future<void> logAdherence({
    required String patientId,
    required DateTime scheduledTime,
    required String status, // 'taken' | 'missed' | 'skipped'
    String? scheduleId,
    String? prescriptionItemId,
    String? medicationName,
  }) async {
    try {
      await supabase.from(Tables.adherenceLogs).insert({
        'patient_id': patientId,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'status': status,
        if (scheduleId != null) 'schedule_id': scheduleId,
        if (prescriptionItemId != null)
          'prescription_item_id': prescriptionItemId,
        if (medicationName != null) 'medication_name': medicationName,
      });
    } catch (e) {
      throw AppException(message: 'Failed to log adherence: $e');
    }
  }

  // ─────────────────────────── ANALYTICS ───────────────────────────────────

  /// Returns daily taken/missed counts for the last [days] days.
  /// Shape: [{'date': '2026-04-01', 'taken': 3, 'missed': 1}, ...]
  Future<List<Map<String, dynamic>>> getAdherenceTrend({int days = 30}) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return [];

      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();

      final data = await supabase
          .from(Tables.adherenceLogs)
          .select('scheduled_time, status')
          .eq('patient_id', uid)
          .gte('scheduled_time', cutoff)
          .order('scheduled_time', ascending: true);

      final logs = List<Map<String, dynamic>>.from(data);

      // Group by date string
      final grouped = <String, Map<String, int>>{};
      for (final log in logs) {
        final dt = DateTime.parse(log['scheduled_time'] as String).toLocal();
        final dateStr =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final entry = grouped.putIfAbsent(
            dateStr, () => {'taken': 0, 'missed': 0, 'skipped': 0});
        final status = log['status'] as String? ?? 'missed';
        entry[status] = (entry[status] ?? 0) + 1;
      }

      return grouped.entries
          .map((e) => {'date': e.key, ...e.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns the next 5 upcoming doses for today.
  /// Shape: [{'medication_name': '…', 'dosage': '…', 'time': '08:00'}, ...]
  Future<List<Map<String, String>>> getUpcomingDoses() async {
    try {
      final schedules = await listByPatient();
      final now = DateTime.now();

      final upcoming = <Map<String, String>>[];
      for (final s in schedules) {
        for (final doseTime in s.todayDoseTimes()) {
          if (doseTime.isAfter(now)) {
            final hh = doseTime.hour.toString().padLeft(2, '0');
            final mm = doseTime.minute.toString().padLeft(2, '0');
            upcoming.add({
              'medication_name': s.medicationName,
              'dosage': s.dosage,
              'time': '$hh:$mm',
              'schedule_id': s.id,
            });
          }
        }
      }

      // Sort by time string
      upcoming.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
      return upcoming.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns true if any dose was scheduled in the last [windowMinutes]
  /// minutes and hasn't been logged as taken yet.
  Future<bool> hasOverdueDose({int windowMinutes = 120}) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return false;

      final schedules = await listByPatient();
      if (schedules.isEmpty) return false;

      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: windowMinutes));

      // Collect recently-due times across all schedules
      final recentlyDue = schedules
          .expand((s) => s.recentlyDueTimes(windowMinutes: windowMinutes))
          .toList();

      if (recentlyDue.isEmpty) return false;

      // Check if any of those were already logged as 'taken'
      final data = await supabase
          .from(Tables.adherenceLogs)
          .select('scheduled_time, status')
          .eq('patient_id', uid)
          .eq('status', 'taken')
          .gte('scheduled_time', windowStart.toUtc().toIso8601String())
          .lte('scheduled_time', now.toUtc().toIso8601String());

      final takenTimes = Set<String>.from(
          List<Map<String, dynamic>>.from(data)
              .map((e) => e['scheduled_time'] as String));

      for (final due in recentlyDue) {
        final key = due.toUtc().toIso8601String();
        if (!takenTimes.any((t) =>
            (DateTime.parse(t).difference(due)).inMinutes.abs() < 10)) {
          return true; // At least one overdue dose
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
