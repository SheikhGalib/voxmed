import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/notification_service.dart';
import '../models/appointment.dart';

/// Provides the AppointmentRepository instance.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

class AppointmentState {
  final List<Appointment> appointments;
  final bool isLoading;
  final AppException? error;

  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  AppointmentState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  AppointmentNotifier(this._repository) : super(const AppointmentState());

  Future<void> fetchAppointments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final appointments = await _repository.listByPatient();
      state = state.copyWith(appointments: appointments, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> fetchUpcoming() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final appointments = await _repository.listUpcoming();
      state = state.copyWith(appointments: appointments, isLoading: false, clearError: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<Appointment?> createAppointment({
    required String doctorId,
    String? hospitalId,
    required DateTime startAt,
    required DateTime endAt,
    AppointmentType type = AppointmentType.inPerson,
    String? reason,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createAppointment(
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
        type: type,
        reason: reason,
        notes: notes,
      );
      state = state.copyWith(
        appointments: [created, ...state.appointments],
        isLoading: false,
        clearError: true,
      );

      // Schedule a local push reminder on the patient's device 15 min before.
      NotificationService().scheduleAppointmentReminder(
        appointmentId: created.id,
        scheduledAt: startAt,
        otherPartyName: created.doctorName ?? 'your doctor',
        isDoctor: false,
      );

      return created;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.cancelAppointment(appointmentId);
      final updated = state.appointments
          .map((appointment) => appointment.id == appointmentId
              ? Appointment(
                  id: appointment.id,
                  patientId: appointment.patientId,
                  doctorId: appointment.doctorId,
                  hospitalId: appointment.hospitalId,
                  scheduledStartAt: appointment.scheduledStartAt,
                  scheduledEndAt: appointment.scheduledEndAt,
                  status: AppointmentStatus.cancelled,
                  type: appointment.type,
                  reason: appointment.reason,
                  notes: appointment.notes,
                  rescheduledFrom: appointment.rescheduledFrom,
                  createdAt: appointment.createdAt,
                  updatedAt: DateTime.now(),
                  doctorName: appointment.doctorName,
                  doctorSpecialty: appointment.doctorSpecialty,
                  doctorAvatarUrl: appointment.doctorAvatarUrl,
                  patientName: appointment.patientName,
                  hospitalName: appointment.hospitalName,
                )
              : appointment)
          .toList();
      state = state.copyWith(appointments: updated, isLoading: false, clearError: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }
}

final appointmentProvider = StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  return AppointmentNotifier(ref.watch(appointmentRepositoryProvider));
});

/// Lists upcoming appointments for the current patient.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(appointmentRepositoryProvider).listUpcoming(patientId: userId);
});

/// Lists all appointments for the current patient.
final patientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(appointmentRepositoryProvider).listByPatient(patientId: userId);
});
