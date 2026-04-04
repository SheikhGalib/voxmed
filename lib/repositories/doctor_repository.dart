import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/doctor.dart';
import '../models/doctor_schedule.dart';

/// Repository for doctor data access.
class DoctorRepository {
  static const String _doctorColumns =
      'id, profile_id, hospital_id, specialty, sub_specialty, qualifications, experience_years, '
      'bio, consultation_fee, patients_count, reviews_count, rating, is_available, chamber_address, '
      'chamber_city, created_at, updated_at, profiles!inner(full_name, avatar_url, email), hospitals(name)';

  static const String _scheduleColumns =
      'id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active, created_at';

  List<Doctor>? _doctorCache;
  final Map<String, List<Doctor>> _specialtyCache = {};
  final Map<String, List<Doctor>> _hospitalDoctorCache = {};
  final Map<String, List<DoctorSchedule>> _scheduleCache = {};

  /// List all available doctors with joined profile data.
  Future<List<Doctor>> listDoctors({int limit = 20, int offset = 0}) async {
    if (offset == 0 && _doctorCache != null && _doctorCache!.isNotEmpty) {
      return _doctorCache!;
    }

    try {
      final data = await supabase
          .from(Tables.doctors)
          .select(_doctorColumns)
          .eq('is_available', true)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);
      final doctors = (data as List).map((e) => Doctor.fromJson(e)).toList();
      if (offset == 0) {
        _doctorCache = doctors;
      }
      return doctors;
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
          .select(_doctorColumns)
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
          .select(_doctorColumns)
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
    final normalized = specialty.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all specialties') {
      return listDoctors();
    }
    if (_specialtyCache.containsKey(normalized)) {
      return _specialtyCache[normalized]!;
    }

    try {
      final data = await supabase
          .from(Tables.doctors)
          .select(_doctorColumns)
          .eq('is_available', true)
          .ilike('specialty', '%$normalized%')
          .order('rating', ascending: false)
          .limit(20);
      final results = (data as List).map((e) => Doctor.fromJson(e)).toList();
      _specialtyCache[normalized] = results;
      return results;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to filter doctors: $e');
    }
  }

  /// Get doctors by hospital.
  Future<List<Doctor>> getByHospital(String hospitalId) async {
    if (_hospitalDoctorCache.containsKey(hospitalId)) {
      return _hospitalDoctorCache[hospitalId]!;
    }

    try {
      final data = await supabase
          .from(Tables.doctors)
          .select(_doctorColumns)
          .eq('is_available', true)
          .eq('hospital_id', hospitalId)
          .order('rating', ascending: false)
          .limit(50);
      final results = (data as List).map((e) => Doctor.fromJson(e)).toList();
      _hospitalDoctorCache[hospitalId] = results;
      return results;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load hospital doctors: $e');
    }
  }

  /// Create a doctor profile (for doctor onboarding).
  Future<Doctor> createDoctorProfile(Map<String, dynamic> data) async {
    try {
      final result = await supabase
          .from(Tables.doctors)
          .insert(data)
          .select(_doctorColumns)
          .single();
      return Doctor.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create doctor profile: $e');
    }
  }

  /// Get schedule for a doctor.
  Future<List<DoctorSchedule>> getSchedule(String doctorId) async {
    if (_scheduleCache.containsKey(doctorId)) {
      return _scheduleCache[doctorId]!;
    }

    try {
      final data = await supabase
          .from(Tables.doctorSchedules)
          .select(_scheduleColumns)
          .eq('doctor_id', doctorId)
          .eq('is_active', true)
          .order('day_of_week');
      final schedules = (data as List).map((e) => DoctorSchedule.fromJson(e)).toList();
      _scheduleCache[doctorId] = schedules;
      return schedules;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load schedule: $e');
    }
  }

  /// Backward-compatible alias.
  Future<List<DoctorSchedule>> getDoctorSchedule(String doctorId) {
    return getSchedule(doctorId);
  }
}
