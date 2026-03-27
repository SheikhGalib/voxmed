import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/appointment.dart';

/// Repository for appointment data access.
class AppointmentRepository {
  /// Create a new appointment.
  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    try {
      final result = await supabase
          .from(Tables.appointments)
          .insert(data)
          .select()
          .single();
      return Appointment.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create appointment: $e');
    }
  }

  /// List appointments for a patient.
  Future<List<Appointment>> listByPatient(String patientId, {int limit = 20}) async {
    try {
      final data = await supabase
          .from(Tables.appointments)
          .select('*, doctors(specialty, profiles(full_name, avatar_url)), hospitals(name)')
          .eq('patient_id', patientId)
          .order('scheduled_start_at', ascending: true)
          .limit(limit);
      return (data as List).map((e) => Appointment.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load appointments: $e');
    }
  }

  /// List upcoming appointments for a patient.
  Future<List<Appointment>> listUpcoming(String patientId) async {
    try {
      final data = await supabase
          .from(Tables.appointments)
          .select('*, doctors(specialty, profiles(full_name, avatar_url)), hospitals(name)')
          .eq('patient_id', patientId)
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
          .select('*, profiles!appointments_patient_id_fkey(full_name, avatar_url)')
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
    await updateStatus(appointmentId, AppointmentStatus.cancelled);
  }
}
