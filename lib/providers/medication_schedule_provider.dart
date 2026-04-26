import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medication_schedule.dart';
import '../repositories/medication_schedule_repository.dart';
import '../repositories/notification_service.dart';

// ─────────────────────────── Repository ──────────────────────────────────────

final medicationScheduleRepositoryProvider =
    Provider<MedicationScheduleRepository>(
        (_) => MedicationScheduleRepository());

// ─────────────────────────── Read providers ───────────────────────────────────

/// All active schedules for the current patient.
final medicationSchedulesProvider =
    FutureProvider<List<MedicationSchedule>>((ref) async {
  return ref
      .read(medicationScheduleRepositoryProvider)
      .listByPatient();
});

/// Next 5 upcoming dose times for today.
/// Shape: [{'medication_name': '...', 'dosage': '...', 'time': 'HH:MM', 'schedule_id': '...'}]
final upcomingDosesProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  return ref
      .read(medicationScheduleRepositoryProvider)
      .getUpcomingDoses();
});

/// 30-day daily adherence trend.
/// Shape: [{'date': 'YYYY-MM-DD', 'taken': n, 'missed': n, 'skipped': n}]
final adherenceTrendProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref
      .read(medicationScheduleRepositoryProvider)
      .getAdherenceTrend(days: 30);
});

/// Detailed 30-day medication intake rows for the commit-rate page.
final adherenceDetailsProvider =
    FutureProvider<List<MedicationAdherenceEntry>>((ref) async {
  return ref
      .read(medicationScheduleRepositoryProvider)
      .getAdherenceDetails(days: 30);
});

/// Returns the first overdue dose from the last 2 hours that hasn't been taken.
/// Returns null if all doses are on track.
final overdueReminderProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(medicationScheduleRepositoryProvider);
  final schedules = await repo.listByPatient();

  for (final s in schedules) {
    final overdueTimes = s.recentlyDueTimes(windowMinutes: 120);
    if (overdueTimes.isEmpty) continue;

    // Return metadata for the first overdue dose
    final t = overdueTimes.first;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return {
      'schedule_id': s.id,
      'medication_name': s.medicationName,
      'dosage': s.dosage,
      'scheduled_time': t,
      'time_label': '$hh:$mm',
    };
  }
  return null;
});

// ─────────────────────────── StateNotifier ────────────────────────────────────

/// Manages create / update / delete of medication schedules and keeps
/// the notification queue in sync.
class MedicationScheduleNotifier
    extends StateNotifier<AsyncValue<List<MedicationSchedule>>> {
  final MedicationScheduleRepository _repo;
  final NotificationService _notif;

  MedicationScheduleNotifier(this._repo, this._notif)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final schedules = await _repo.listByPatient();
      state = AsyncValue.data(schedules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<MedicationSchedule> create(MedicationSchedule schedule) async {
    final created = await _repo.create(schedule);
    await _notif.scheduleAllReminders(created);
    await _load();
    return created;
  }

  Future<void> update(MedicationSchedule schedule) async {
    // Cancel old reminders, save, schedule new ones
    await _notif.cancelScheduleReminders(schedule);
    final updated = await _repo.update(schedule);
    await _notif.scheduleAllReminders(updated);
    await _load();
  }

  Future<void> delete(String scheduleId) async {
    final current = state.valueOrNull ?? [];
    final target = current.where((s) => s.id == scheduleId).firstOrNull;
    if (target != null) {
      await _notif.cancelScheduleReminders(target);
    }
    await _repo.delete(scheduleId);
    await _load();
  }

  /// Re-schedules ALL active reminders (e.g. after sign-in or app restart).
  Future<void> rescheduleAll() async {
    final schedules = state.valueOrNull ?? await _repo.listByPatient();
    for (final s in schedules) {
      await _notif.scheduleAllReminders(s);
    }
  }
}

final medicationScheduleNotifierProvider = StateNotifierProvider<
    MedicationScheduleNotifier, AsyncValue<List<MedicationSchedule>>>((ref) {
  return MedicationScheduleNotifier(
    ref.read(medicationScheduleRepositoryProvider),
    NotificationService(),
  );
});
