import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/error_handler.dart';
import '../repositories/hospital_repository.dart';
import '../models/hospital.dart';

/// Provides the HospitalRepository instance.
final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
});

class HospitalState {
  final List<Hospital> hospitals;
  final bool isLoading;
  final AppException? error;

  const HospitalState({
    this.hospitals = const [],
    this.isLoading = false,
    this.error,
  });

  HospitalState copyWith({
    List<Hospital>? hospitals,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
  }) {
    return HospitalState(
      hospitals: hospitals ?? this.hospitals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HospitalNotifier extends StateNotifier<HospitalState> {
  final HospitalRepository _repository;

  HospitalNotifier(this._repository) : super(const HospitalState());

  Future<void> fetchHospitals({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.hospitals.isNotEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hospitals = await _repository.listHospitals();
      state = state.copyWith(hospitals: hospitals, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hospitals = await _repository.searchHospitals(query);
      state = state.copyWith(hospitals: hospitals, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final hospitalProvider = StateNotifierProvider<HospitalNotifier, HospitalState>((ref) {
  return HospitalNotifier(ref.watch(hospitalRepositoryProvider));
});

/// Lists all hospitals, sorted by rating.
final hospitalsProvider = FutureProvider<List<Hospital>>((ref) async {
  return ref.read(hospitalRepositoryProvider).listHospitals();
});

/// Search hospitals by query.
final hospitalSearchProvider = FutureProvider.family<List<Hospital>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.read(hospitalRepositoryProvider).listHospitals();
  }
  return ref.read(hospitalRepositoryProvider).searchHospitals(query);
});
