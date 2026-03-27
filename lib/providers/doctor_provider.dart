import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/doctor_repository.dart';
import '../models/doctor.dart';

/// Provides the DoctorRepository instance.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository();
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

/// Get a single doctor by ID.
final doctorDetailProvider = FutureProvider.family<Doctor, String>((ref, doctorId) async {
  return ref.read(doctorRepositoryProvider).getDoctor(doctorId);
});
