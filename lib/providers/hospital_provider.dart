import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/hospital_repository.dart';
import '../models/hospital.dart';

/// Provides the HospitalRepository instance.
final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
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
