import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../models/prescription.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/medical_record_repository.dart';
import '../repositories/prescription_repository.dart';
import 'appointment_provider.dart';
import 'medical_record_provider.dart';
import 'prescription_provider.dart';

/// Doctor's distinct patient list (by doctorId).
final doctorPatientsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, doctorId) async {
    final repo = ref.read(appointmentRepositoryProvider);
    return repo.listDoctorPatients(doctorId);
  },
);

/// Doctor's appointments for a date range.
final doctorAppointmentsRangeProvider = FutureProvider.family<
    List<Appointment>,
    ({String doctorId, DateTime start, DateTime end})>(
  (ref, params) async {
    final repo = ref.read(appointmentRepositoryProvider);
    return repo.listByDoctorRange(params.doctorId, params.start, params.end);
  },
);

/// All visits between a doctor and a specific patient (for analytics).
final patientVisitsForDoctorProvider = FutureProvider.family<
    List<Appointment>, ({String doctorId, String patientId})>(
  (ref, params) async {
    final repo = ref.read(appointmentRepositoryProvider);
    return repo.listPatientVisitsForDoctor(params.doctorId, params.patientId);
  },
);

/// All prescriptions for a given patient (by patient ID).
final patientPrescriptionsByIdProvider =
    FutureProvider.family<List<Prescription>, String>(
  (ref, patientId) async {
    final repo = ref.read(prescriptionRepositoryProvider);
    return repo.listByPatient(patientId: patientId, limit: 100);
  },
);

/// Medical records for a given patient (by patient ID, for doctor access).
final patientRecordsByIdProvider =
    FutureProvider.family<List<MedicalRecord>, String>(
  (ref, patientId) async {
    final repo = ref.read(medicalRecordRepositoryProvider);
    return repo.listByPatientId(patientId);
  },
);

/// Notifier to create prescriptions (doctor writes a prescription).
class CreatePrescriptionNotifier extends StateNotifier<AsyncValue<void>> {
  final PrescriptionRepository _repo;

  CreatePrescriptionNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<bool> createPrescription({
    required String patientId,
    required String doctorId,
    String? diagnosis,
    String? notes,
    DateTime? validUntil,
    required List<Map<String, dynamic>> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPrescriptionWithItems(
        patientId: patientId,
        doctorId: doctorId,
        diagnosis: diagnosis,
        notes: notes,
        validUntil: validUntil,
        items: items,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createPrescriptionProvider = StateNotifierProvider.autoDispose<
    CreatePrescriptionNotifier, AsyncValue<void>>(
  (ref) =>
      CreatePrescriptionNotifier(ref.read(prescriptionRepositoryProvider)),
);
