import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/appointment.dart';

/// Repository for appointment data access.
class AppointmentRepository {
  static const String _appointmentColumns =
      'id, patient_id, doctor_id, hospital_id, scheduled_start_at, scheduled_end_at, status, type, reason, notes, '
      'rescheduled_from, created_at, updated_at, doctors(specialty, profiles(full_name, avatar_url)), hospitals(name), '
      'profiles!appointments_patient_id_fkey(full_name, avatar_url)';

  /// Create a new appointment.
  Future<Appointment> createAppointment({
    required String doctorId,
    String? hospitalId,
    required DateTime scheduledStartAt,
    required DateTime scheduledEndAt,
    AppointmentType type = AppointmentType.inPerson,
    String? reason,
    String? notes,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw const AppException(message: 'Please log in to book an appointment.');
    }

    final startUtc = scheduledStartAt.toUtc();
    final endUtc = scheduledEndAt.toUtc();
    if (!endUtc.isAfter(startUtc)) {
      throw const AppException(message: 'Appointment end time must be after start time.');
    }

    try {
      final conflicts = await supabase
          .from(Tables.appointments)
          .select('id')
          .eq('doctor_id', doctorId)
          .inFilter('status', ['scheduled', 'confirmed'])
          .lt('scheduled_start_at', endUtc.toIso8601String())
          .gt('scheduled_end_at', startUtc.toIso8601String())
          .limit(1);

      if ((conflicts as List).isNotEmpty) {
        throw const AppException(
          message: 'Selected slot is no longer available. Please choose another time.',
          code: 'booking_conflict',
        );
      }

      final payload = <String, dynamic>{
        'patient_id': currentUser.id,
        'doctor_id': doctorId,
        'hospital_id': ?hospitalId,
        'scheduled_start_at': startUtc.toIso8601String(),
        'scheduled_end_at': endUtc.toIso8601String(),
        'status': AppointmentStatus.scheduled.value,
        'type': type.value,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final result = await supabase
          .from(Tables.appointments)
          .insert(payload)
          .select(_appointmentColumns)
          .single();
      return Appointment.fromJson(result);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create appointment: $e');
    }
  }

  /// Backward-compatible create method.
  Future<Appointment> createAppointmentFromMap(Map<String, dynamic> data) async {
    return createAppointment(
      doctorId: data['doctor_id'] as String,
      hospitalId: data['hospital_id'] as String?,
      scheduledStartAt: DateTime.parse(data['scheduled_start_at'] as String),
      scheduledEndAt: DateTime.parse(data['scheduled_end_at'] as String),
      type: AppointmentType.fromString(data['type'] as String? ?? 'in_person'),
      reason: data['reason'] as String?,
      notes: data['notes'] as String?,
    );
  }

  /// Cancel an appointment.
  Future<void> cancelAppointment(String appointmentId) async {
    await updateStatus(appointmentId, AppointmentStatus.cancelled);
  }

  /// List appointments for current patient or provided patient id.
  Future<List<Appointment>> listByPatient({String? patientId, int limit = 20}) async {
    final effectivePatientId = patientId ?? supabase.auth.currentUser?.id;
    if (effectivePatientId == null) {
      throw const AppException(message: 'Please log in to view appointments.');
    }

    try {
      final data = await supabase
          .from(Tables.appointments)
          .select(_appointmentColumns)
          .eq('patient_id', effectivePatientId)
          .order('scheduled_start_at', ascending: true)
          .limit(limit);
      return (data as List).map((e) => Appointment.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load appointments: $e');
    }
  }

  /// List upcoming appointments for current patient or provided patient id.
  Future<List<Appointment>> listUpcoming({String? patientId}) async {
    final effectivePatientId = patientId ?? supabase.auth.currentUser?.id;
    if (effectivePatientId == null) {
      throw const AppException(message: 'Please log in to view appointments.');
    }

    try {
      final data = await supabase
          .from(Tables.appointments)
          .select(_appointmentColumns)
          .eq('patient_id', effectivePatientId)
          .inFilter('status', ['scheduled', 'confirmed'])
          .gte('scheduled_start_at', DateTime.now().toUtc().toIso8601String())
          .order('scheduled_start_at', ascending: true)
          .limit(10);
      return (data as List).map((e) => Appointment.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load upcoming appointments: $e');
    }
  }

  /// List appointments for a doctor (today's patients).
  Future<List<Appointment>> listByDoctor(String doctorId, {DateTime? date}) async {
    try {
      var query = supabase
          .from(Tables.appointments)
          .select(_appointmentColumns)
          .eq('doctor_id', doctorId);

      if (date != null) {
        final dayStart = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();
        query = query.gte('scheduled_start_at', dayStart).lte('scheduled_start_at', dayEnd);
      }

      final data = await query.order('scheduled_start_at', ascending: true);
      return (data as List).map((e) => Appointment.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load doctor appointments: $e');
    }
  }

  /// Update appointment status.
  Future<void> updateStatus(String appointmentId, AppointmentStatus status) async {
    try {
      await supabase
          .from(Tables.appointments)
          .update({'status': status.value})
          .eq('id', appointmentId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to update appointment: $e');
    }
  }

  /// Cancel an appointment.
  Future<void> cancel(String appointmentId) async {
    await cancelAppointment(appointmentId);
  }
}
