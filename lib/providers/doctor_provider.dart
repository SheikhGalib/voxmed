import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/error_handler.dart';
import '../repositories/doctor_repository.dart';
import '../models/doctor.dart';
import '../models/doctor_schedule.dart';

/// Provides the DoctorRepository instance.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository();
});

class DoctorState {
  final List<Doctor> doctors;
  final bool isLoading;
  final AppException? error;

  const DoctorState({
    this.doctors = const [],
    this.isLoading = false,
    this.error,
  });

  DoctorState copyWith({
    List<Doctor>? doctors,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
  }) {
    return DoctorState(
      doctors: doctors ?? this.doctors,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DoctorNotifier extends StateNotifier<DoctorState> {
  final DoctorRepository _repository;

  DoctorNotifier(this._repository) : super(const DoctorState());

  Future<void> listDoctors() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final doctors = await _repository.listDoctors();
      state = state.copyWith(doctors: doctors, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> filterBySpecialty(String specialty) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final doctors = await _repository.filterBySpecialty(specialty);
      state = state.copyWith(doctors: doctors, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> getByHospital(String hospitalId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final doctors = await _repository.getByHospital(hospitalId);
      state = state.copyWith(doctors: doctors, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  return DoctorNotifier(ref.watch(doctorRepositoryProvider));
});

/// Lists only approved doctors (via public_doctors view). Refreshes on Realtime updates.
final doctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  // Realtime: invalidate when a doctor becomes fully approved.
  final channel = supabase.channel('public:doctors');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'doctors',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord['status'] == 'approved' &&
              newRecord['approved_by_hospital'] == true) {
            ref.invalidateSelf();
          }
        },
      )
      .subscribe();

  ref.onDispose(() => channel.unsubscribe());

  return ref.read(doctorRepositoryProvider).listDoctors();
});

/// Filter approved doctors by specialty.
final doctorsBySpecialtyProvider = FutureProvider.family<List<Doctor>, String>((ref, specialty) async {
  if (specialty.isEmpty || specialty == 'All Specialties') {
    return ref.read(doctorRepositoryProvider).listDoctors();
  }
  return ref.read(doctorRepositoryProvider).filterBySpecialty(specialty);
});

/// Approved doctors for a specific hospital.
final doctorsByHospitalProvider = FutureProvider.family<List<Doctor>, String>((ref, hospitalId) async {
  return ref.read(doctorRepositoryProvider).getByHospital(hospitalId);
});

/// Get a single approved doctor by ID.
final doctorDetailProvider = FutureProvider.family<Doctor, String>((ref, doctorId) async {
  return ref.read(doctorRepositoryProvider).getDoctor(doctorId);
});

final doctorScheduleProvider = FutureProvider.family<List<DoctorSchedule>, String>((ref, doctorId) async {
  return ref.read(doctorRepositoryProvider).getSchedule(doctorId);
});

/// Fetch the currently logged-in doctor's own profile (from doctors table, not view).
/// Used to check approval status on the doctor dashboard.
final currentDoctorProvider = FutureProvider<Doctor?>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.read(doctorRepositoryProvider).getDoctorByProfileId(userId);
});
