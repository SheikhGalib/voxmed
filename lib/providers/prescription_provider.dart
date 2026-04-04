import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/prescription.dart';
import '../repositories/prescription_repository.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository();
});

/// Prescriptions for the current patient.
final patientPrescriptionsProvider = FutureProvider<List<Prescription>>((ref) async {
  final repo = ref.read(prescriptionRepositoryProvider);
  return repo.listByPatient();
});

/// Pending renewal requests for the logged-in doctor.
final pendingRenewalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
final adherenceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return {};

  try {
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String();
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
final doctorTodayAppointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  try {
    final doctorRow = await supabase
        .from(Tables.doctors)
        .select('id')
        .eq('profile_id', uid)
        .maybeSingle();
    if (doctorRow == null) return [];

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toUtc().toIso8601String();

    final data = await supabase
        .from(Tables.appointments)
        .select('id, scheduled_start_at, scheduled_end_at, status, type, reason, profiles!appointments_patient_id_fkey(full_name, avatar_url)')
        .eq('doctor_id', doctorRow['id'])
        .gte('scheduled_start_at', startOfDay)
        .lte('scheduled_start_at', endOfDay)
        .order('scheduled_start_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    return [];
  }
});

/// Doctor's active patient count + stats.
final doctorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return {};

  try {
    final doctorRow = await supabase
        .from(Tables.doctors)
        .select('id, patients_count, reviews_count, rating')
        .eq('profile_id', uid)
        .maybeSingle();
    if (doctorRow == null) return {};

    // Count pending renewals
    final renewals = await supabase
        .from(Tables.prescriptionRenewals)
        .select('id')
        .eq('doctor_id', doctorRow['id'])
        .eq('status', 'pending');

    // Count pending lab reviews (medical records without notes from this doctor)
    final labReviews = await supabase
        .from(Tables.medicalRecords)
        .select('id')
        .eq('doctor_id', doctorRow['id'])
        .eq('record_type', 'lab_result')
        .order('created_at', ascending: false)
        .limit(20);

    return {
      'patients_count': doctorRow['patients_count'] ?? 0,
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
final consultationSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
        .select('session_id, role, consultation_sessions(id, title, status, notes, soap_note, created_at, profiles!consultation_sessions_patient_id_fkey(full_name, avatar_url, date_of_birth, gender, blood_group))')
        .eq('doctor_id', doctorRow['id'])
        .order('joined_at', ascending: false);

    return List<Map<String, dynamic>>.from(sessions);
  } catch (e) {
    return [];
  }
});

/// AI Conversations for the current patient.
final aiConversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  try {
    final data = await supabase
        .from(Tables.aiConversations)
        .select('id, title, triage_result, created_at, updated_at')
        .eq('patient_id', uid)
        .order('updated_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    return [];
  }
});

/// AI Messages for a given conversation.
final aiMessagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, conversationId) async {
  try {
    final data = await supabase
        .from(Tables.aiMessages)
        .select('id, role, content, metadata, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    return [];
  }
});
