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

      return List<Map<String, dynamic>>.from(
        data,
      ).map(MedicationSchedule.fromJson).toList();
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
      final payload = <String, dynamic>{
        'patient_id': patientId,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'status': status,
      };
      if (scheduleId != null) {
        payload['schedule_id'] = scheduleId;
      }
      if (prescriptionItemId != null) {
        payload['prescription_item_id'] = prescriptionItemId;
      }
      if (medicationName != null) {
        payload['medication_name'] = medicationName;
      }

      await supabase.from(Tables.adherenceLogs).insert(payload);
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
          dateStr,
          () => {'taken': 0, 'missed': 0, 'skipped': 0},
        );
        final status = log['status'] as String? ?? 'missed';
        entry[status] = (entry[status] ?? 0) + 1;
      }

      return grouped.entries.map((e) => {'date': e.key, ...e.value}).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns detailed intake rows for the commit-rate page.
  Future<List<MedicationAdherenceEntry>> getAdherenceDetails({
    int days = 30,
  }) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return [];

      final now = DateTime.now();
      final cutoff = now.subtract(Duration(days: days));

      final data = await supabase
          .from(Tables.adherenceLogs)
          .select(
            'id, schedule_id, prescription_item_id, medication_name, scheduled_time, response_time, status',
          )
          .eq('patient_id', uid)
          .gte('scheduled_time', cutoff.toUtc().toIso8601String())
          .order('scheduled_time', ascending: false);

      final entries = List<Map<String, dynamic>>.from(
        data,
      ).map(MedicationAdherenceEntry.fromJson).toList();

      final schedules = await listByPatient();
      final logged = entries
          .map((e) => _doseKey(e.scheduleId, e.medicationName, e.scheduledTime))
          .toSet();

      for (final schedule in schedules) {
        final start = schedule.createdAt.isAfter(cutoff)
            ? schedule.createdAt
            : cutoff;
        for (
          var day = DateTime(start.year, start.month, start.day);
          !day.isAfter(now);
          day = day.add(const Duration(days: 1))
        ) {
          if (schedule.daysOfWeek != null &&
              !schedule.daysOfWeek!.contains(day.weekday)) {
            continue;
          }

          for (final timeStr in schedule.timesOfDay) {
            final doseTime = _doseTimeForDay(day, timeStr);
            if (doseTime.isAfter(now)) continue;

            final key = _doseKey(
              schedule.id,
              schedule.medicationName,
              doseTime,
            );
            if (logged.contains(key)) continue;

            entries.add(
              MedicationAdherenceEntry.derivedMissed(
                schedule: schedule,
                scheduledTime: doseTime,
              ),
            );
            logged.add(key);
          }
        }
      }

      entries.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return entries;
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
              'time': MedicationSchedule.formatDoseTimeLabel(doseTime),
              'time_24h': '$hh:$mm',
              'schedule_id': s.id,
            });
          }
        }
      }

      upcoming.sort(
        (a, b) => (a['time_24h'] ?? '').compareTo(b['time_24h'] ?? ''),
      );
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
        List<Map<String, dynamic>>.from(
          data,
        ).map((e) => e['scheduled_time'] as String),
      );

      for (final due in recentlyDue) {
        if (!takenTimes.any(
          (t) => (DateTime.parse(t).difference(due)).inMinutes.abs() < 10,
        )) {
          return true; // At least one overdue dose
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  DateTime _doseTimeForDay(DateTime day, String timeStr) {
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  String _doseKey(String? scheduleId, String medicationName, DateTime time) {
    final local = time.toLocal();
    final rounded = DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    return '${scheduleId ?? medicationName}:${rounded.toIso8601String()}';
  }
}
