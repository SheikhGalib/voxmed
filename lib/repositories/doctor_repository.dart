import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/doctor.dart';
import '../models/doctor_schedule.dart';

/// Repository for doctor data access.
class DoctorRepository {
  /// List all available doctors with joined profile data.
  Future<List<Doctor>> listDoctors({int limit = 20, int offset = 0}) async {
    try {
      final data = await supabase
          .from(Tables.doctors)
          .select('*, profiles!inner(full_name, avatar_url, email), hospitals(name)')
          .eq('is_available', true)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((e) => Doctor.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load doctors: $e');
    }
  }

  /// Get a single doctor by ID with joined data.
  Future<Doctor> getDoctor(String id) async {
    try {
      final data = await supabase
          .from(Tables.doctors)
          .select('*, profiles!inner(full_name, avatar_url, email), hospitals(name)')
          .eq('id', id)
          .single();
      return Doctor.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load doctor: $e');
    }
  }

  /// Get doctor record by profile ID (for logged-in doctors).
  Future<Doctor?> getDoctorByProfileId(String profileId) async {
    try {
      final data = await supabase
          .from(Tables.doctors)
          .select('*, profiles!inner(full_name, avatar_url, email), hospitals(name)')
          .eq('profile_id', profileId)
          .maybeSingle();
      if (data == null) return null;
      return Doctor.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load doctor profile: $e');
    }
  }

  /// Filter doctors by specialty.
  Future<List<Doctor>> filterBySpecialty(String specialty) async {
    try {
      final data = await supabase
          .from(Tables.doctors)
          .select('*, profiles!inner(full_name, avatar_url, email), hospitals(name)')
          .eq('is_available', true)
          .ilike('specialty', '%$specialty%')
          .order('rating', ascending: false)
          .limit(20);
      return (data as List).map((e) => Doctor.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to filter doctors: $e');
    }
  }

  /// Create a doctor profile (for doctor onboarding).
  Future<Doctor> createDoctorProfile(Map<String, dynamic> data) async {
    try {
      final result = await supabase
          .from(Tables.doctors)
          .insert(data)
          .select('*, profiles!inner(full_name, avatar_url, email), hospitals(name)')
          .single();
      return Doctor.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create doctor profile: $e');
    }
  }

  /// Get schedule for a doctor.
  Future<List<DoctorSchedule>> getDoctorSchedule(String doctorId) async {
    try {
      final data = await supabase
          .from(Tables.doctorSchedules)
          .select()
          .eq('doctor_id', doctorId)
          .eq('is_active', true)
          .order('day_of_week');
      return (data as List).map((e) => DoctorSchedule.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load schedule: $e');
    }
  }
}
