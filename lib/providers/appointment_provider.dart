import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../repositories/appointment_repository.dart';
import '../models/appointment.dart';

/// Provides the AppointmentRepository instance.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

/// Lists upcoming appointments for the current patient.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(appointmentRepositoryProvider).listUpcoming(userId);
});

/// Lists all appointments for the current patient.
final patientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(appointmentRepositoryProvider).listByPatient(userId);
});
