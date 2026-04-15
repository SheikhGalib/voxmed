import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Lists all available doctors.
final doctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  return ref.read(doctorRepositoryProvider).listDoctors();
});

/// Filter doctors by specialty.
final doctorsBySpecialtyProvider = FutureProvider.family<List<Doctor>, String>((ref, specialty) async {
  if (specialty.isEmpty || specialty == 'All Specialties') {
    return ref.read(doctorRepositoryProvider).listDoctors();
  }
  return ref.read(doctorRepositoryProvider).filterBySpecialty(specialty);
});

final doctorsByHospitalProvider = FutureProvider.family<List<Doctor>, String>((ref, hospitalId) async {
  return ref.read(doctorRepositoryProvider).getByHospital(hospitalId);
});

/// Get a single doctor by ID.
final doctorDetailProvider = FutureProvider.family<Doctor, String>((ref, doctorId) async {
  return ref.read(doctorRepositoryProvider).getDoctor(doctorId);
});

final doctorScheduleProvider = FutureProvider.family<List<DoctorSchedule>, String>((ref, doctorId) async {
  return ref.read(doctorRepositoryProvider).getSchedule(doctorId);
});
