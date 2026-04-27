import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/prescription.dart';
import '../repositories/ai_repository.dart';
import '../repositories/notification_service.dart';
import '../repositories/prescription_repository.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

/// Prescriptions for the current patient.
final patientPrescriptionsProvider = FutureProvider<List<Prescription>>((
  ref,
) async {
  final repo = ref.read(prescriptionRepositoryProvider);
  return repo.listByPatient();
});

/// Pending renewal requests for the logged-in doctor.
final pendingRenewalsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(prescriptionRepositoryProvider);
  // Look up doctor row from profile id
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  final doctorRow = await supabase
      .from(Tables.doctors)
      .select('id')
      .eq('profile_id', uid)
      .maybeSingle();
  if (doctorRow == null) return [];

  return repo.listPendingRenewals(doctorRow['id'] as String);
});

/// Adherence statistics for the current patient (last 30 days).
final adherenceStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return {};

  try {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toUtc()
        .toIso8601String();
    final data = await supabase
        .from(Tables.adherenceLogs)
        .select('status')
        .eq('patient_id', uid)
        .gte('scheduled_time', cutoff);

    final logs = List<Map<String, dynamic>>.from(data);
    final total = logs.length;
    final taken = logs.where((l) => l['status'] == 'taken').length;
    final missed = logs.where((l) => l['status'] == 'missed').length;
    final skipped = logs.where((l) => l['status'] == 'skipped').length;
    final rate = total > 0 ? (taken / total * 100).round() : 0;

    return {
      'total': total,
      'taken': taken,
      'missed': missed,
      'skipped': skipped,
      'rate': rate,
    };
  } catch (e) {
    return {'total': 0, 'taken': 0, 'missed': 0, 'skipped': 0, 'rate': 0};
  }
});

/// Wearable data for the current patient (latest readings).
final wearableDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return {};

  try {
    // Get latest of each metric type
    final heartRate = await supabase
        .from(Tables.wearableData)
        .select('value, recorded_at, source')
        .eq('patient_id', uid)
        .eq('metric_type', 'heart_rate')
        .order('recorded_at', ascending: false)
        .limit(7);

    final bp = await supabase
        .from(Tables.wearableData)
        .select('value, recorded_at, source')
        .eq('patient_id', uid)
        .eq('metric_type', 'blood_pressure')
        .order('recorded_at', ascending: false)
        .limit(7);

    final spo2 = await supabase
        .from(Tables.wearableData)
        .select('value, recorded_at, source')
        .eq('patient_id', uid)
        .eq('metric_type', 'spo2')
        .order('recorded_at', ascending: false)
        .limit(1);

    final sleep = await supabase
        .from(Tables.wearableData)
        .select('value, recorded_at, source')
        .eq('patient_id', uid)
        .eq('metric_type', 'sleep')
        .order('recorded_at', ascending: false)
        .limit(1);

    return {
      'heart_rate': List<Map<String, dynamic>>.from(heartRate),
      'blood_pressure': List<Map<String, dynamic>>.from(bp),
      'spo2': List<Map<String, dynamic>>.from(spo2),
      'sleep': List<Map<String, dynamic>>.from(sleep),
    };
  } catch (e) {
    return {};
  }
});

/// Doctor's appointment list for today (clinical dashboard schedule).
/// Subscribes to Supabase Realtime so new bookings and status changes
/// appear instantly without a manual refresh.
final doctorTodayAppointmentsProvider =
    AsyncNotifierProvider<_DoctorTodayNotifier, List<Map<String, dynamic>>>(
  _DoctorTodayNotifier.new,
);

class _DoctorTodayNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return [];

    final doctorRow = await supabase
        .from(Tables.doctors)
        .select('id')
        .eq('profile_id', uid)
        .maybeSingle();
    if (doctorRow == null) return [];

    final doctorId = doctorRow['id'] as String;

    // Real-time: any INSERT / UPDATE / DELETE on appointments for this doctor
    _channel?.unsubscribe();
    _channel = supabase
        .channel('doctor_today_appts:$doctorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.appointments,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (_) => _reload(doctorId),
        )
        .subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    return _fetch(doctorId);
  }

  Future<void> _reload(String doctorId) async {
    state = await AsyncValue.guard(() => _fetch(doctorId));
  }

  Future<List<Map<String, dynamic>>> _fetch(String doctorId) async {
    try {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      final data = await supabase
          .from(Tables.appointments)
          .select(
            'id, scheduled_start_at, scheduled_end_at, status, type, reason, '
            'profiles!appointments_patient_id_fkey(full_name, avatar_url)',
          )
          .eq('doctor_id', doctorId)
          .gte('scheduled_start_at', startOfDay)
          .lte('scheduled_start_at', endOfDay)
          .order('scheduled_start_at', ascending: true);

      final fetched = List<Map<String, dynamic>>.from(data);
      _scheduleLocalReminders(fetched);
      return fetched;
    } catch (_) {
      return [];
    }
  }

  /// Schedules local push reminders on the doctor's device for each upcoming
  /// appointment in [appointments] that is still in the future.
  /// Uses a stable ID so re-scheduling on every realtime reload is idempotent.
  void _scheduleLocalReminders(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    for (final appt in appointments) {
      final startStr = appt['scheduled_start_at'] as String?;
      final apptId = appt['id'] as String?;
      if (startStr == null || apptId == null) continue;

      final startAt = DateTime.tryParse(startStr)?.toLocal();
      if (startAt == null) continue;

      // Only schedule if the reminder time (15 min before) is still in the future.
      if (startAt.subtract(const Duration(minutes: 15)).isBefore(now)) continue;

      final patientProfile = appt['profiles'] as Map<String, dynamic>?;
      final patientName = patientProfile?['full_name'] as String? ?? 'Patient';

      NotificationService().scheduleAppointmentReminder(
        appointmentId: apptId,
        scheduledAt: startAt,
        otherPartyName: patientName,
        isDoctor: true,
      );
    }
  }
}

/// Doctor's active patient count + stats.
/// "Active patients" = distinct patients with at least one COMPLETED appointment
/// with this doctor. This updates in real time as the hospital staff marks
/// appointments complete — no dependency on the stale `patients_count` column.
final doctorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return {};

  try {
    final doctorRow = await supabase
        .from(Tables.doctors)
        .select('id, reviews_count, rating')
        .eq('profile_id', uid)
        .maybeSingle();
    if (doctorRow == null) return {};

    // Count distinct patients with at least one completed appointment.
    final completedAppts = await supabase
        .from(Tables.appointments)
        .select('patient_id')
        .eq('doctor_id', doctorRow['id'])
        .eq('status', 'completed');
    final distinctPatients = (completedAppts as List)
        .map((e) => e['patient_id'] as String)
        .toSet()
        .length;

    // Count pending renewals
    final renewals = await supabase
        .from(Tables.prescriptionRenewals)
        .select('id')
        .eq('doctor_id', doctorRow['id'])
        .eq('status', 'pending');

    // Count unreviewed lab results uploaded for this doctor
    final labReviews = await supabase
        .from(Tables.medicalRecords)
        .select('id')
        .eq('doctor_id', doctorRow['id'])
        .eq('record_type', 'lab_result')
        .order('created_at', ascending: false)
        .limit(20);

    return {
      'patients_count': distinctPatients,
      'rating': doctorRow['rating'] ?? 0.0,
      'reviews_count': doctorRow['reviews_count'] ?? 0,
      'pending_renewals': (renewals as List).length,
      'pending_labs': (labReviews as List).length,
    };
  } catch (e) {
    return {};
  }
});

/// Consultation sessions for a doctor.
final consultationSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  try {
    final doctorRow = await supabase
        .from(Tables.doctors)
        .select('id')
        .eq('profile_id', uid)
        .maybeSingle();
    if (doctorRow == null) return [];

    final sessions = await supabase
        .from(Tables.consultationMembers)
        .select(
          'session_id, role, consultation_sessions(id, title, status, notes, soap_note, created_at, profiles!consultation_sessions_patient_id_fkey(full_name, avatar_url, date_of_birth, gender, blood_group))',
        )
        .eq('doctor_id', doctorRow['id'])
        .order('joined_at', ascending: false);

    return List<Map<String, dynamic>>.from(sessions);
  } catch (e) {
    return [];
  }
});

/// AI Conversations for the current patient.
final aiConversationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(aiRepositoryProvider);
  try {
    return repo.listConversations(limit: 20);
  } catch (_) {
    return [];
  }
});

/// AI Messages for a given conversation.
final aiMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      conversationId,
    ) async {
      final repo = ref.read(aiRepositoryProvider);
      try {
        return repo.listMessages(conversationId);
      } catch (_) {
        return [];
      }
    });
