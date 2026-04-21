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
      'chamber_city, created_at, updated_at, department, license_number, status, approved_by_hospital, '
      'room_number, profiles(full_name, avatar_url, email), hospitals(name)';

  static const String _scheduleColumns =
      'id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active, created_at';

  List<Doctor>? _doctorCache;
  final Map<String, List<Doctor>> _specialtyCache = {};
  final Map<String, List<Doctor>> _hospitalDoctorCache = {};
  final Map<String, List<DoctorSchedule>> _scheduleCache = {};

  void _clearCaches() {
    _doctorCache = null;
    _specialtyCache.clear();
    _hospitalDoctorCache.clear();
    _scheduleCache.clear();
  }

  /// List all approved doctors (via public_doctors view).
  Future<List<Doctor>> listDoctors({int limit = 20, int offset = 0}) async {
    if (offset == 0 && _doctorCache != null && _doctorCache!.isNotEmpty) {
      return _doctorCache!;
    }

    try {
      final data = await supabase
          .from(Tables.publicDoctors)
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

  /// Get a single approved doctor by ID (patient-facing).
  Future<Doctor> getDoctor(String id) async {
    try {
      final data = await supabase
          .from(Tables.publicDoctors)
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

  /// Filter approved doctors by specialty.
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
          .from(Tables.publicDoctors)
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

  /// Get approved doctors by hospital.
  Future<List<Doctor>> getByHospital(String hospitalId) async {
    if (_hospitalDoctorCache.containsKey(hospitalId)) {
      return _hospitalDoctorCache[hospitalId]!;
    }

    try {
      final data = await supabase
          .from(Tables.publicDoctors)
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

  /// Create a full doctor profile during registration.
  /// Inserts into the doctors table with status=pending.
  Future<void> createFullDoctorProfile({
    required String profileId,
    required String hospitalId,
    required String specialty,
    required String department,
    required String licenseNumber,
    required List<String> qualifications,
  }) async {
    try {
      await supabase.from(Tables.doctors).insert({
        'profile_id': profileId,
        'hospital_id': hospitalId,
        'specialty': specialty,
        'department': department,
        'license_number': licenseNumber,
        'qualifications': qualifications,
        'status': 'pending',
        'approved_by_hospital': false,
        'is_available': false,
      });
      _clearCaches();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create doctor profile: $e');
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
      _clearCaches();
      return Doctor.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create doctor profile: $e');
    }
  }

  /// Ensure a doctor-role profile has a corresponding doctors row.
  Future<Doctor> ensureDoctorProfile({
    required String profileId,
    String specialty = 'General Medicine',
  }) async {
    final existing = await getDoctorByProfileId(profileId);
    if (existing != null) {
      return existing;
    }

    try {
      final result = await supabase
          .from(Tables.doctors)
          .insert({
            'profile_id': profileId,
            'specialty': specialty,
            'is_available': true,
          })
          .select(_doctorColumns)
          .single();
      _clearCaches();
      return Doctor.fromJson(result);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final doctor = await getDoctorByProfileId(profileId);
        if (doctor != null) return doctor;
      }
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to ensure doctor profile: $e');
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
