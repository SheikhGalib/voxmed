import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/prescription.dart';

class PrescriptionRepository {
  static const String _prescriptionColumns =
      'id, patient_id, doctor_id, appointment_id, diagnosis, notes, status, '
      'issued_date, valid_until, created_at, updated_at, '
      'doctors(specialty, profiles(full_name, avatar_url)), '
      'prescription_items(id, prescription_id, medication_name, dosage, frequency, duration_days, instructions, quantity, remaining, created_at)';

  /// List prescriptions for a patient.
  Future<List<Prescription>> listByPatient({String? patientId, int limit = 50}) async {
    final uid = patientId ?? supabase.auth.currentUser?.id;
    if (uid == null) throw const AppException(message: 'Not authenticated.');

    try {
      final data = await supabase
          .from(Tables.prescriptions)
          .select(_prescriptionColumns)
          .eq('patient_id', uid)
          .order('issued_date', ascending: false)
          .limit(limit);
      return (data as List).map((e) => Prescription.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load prescriptions: $e');
    }
  }

  /// List prescriptions written by a doctor.
  Future<List<Prescription>> listByDoctor({String? doctorId, int limit = 50}) async {
    try {
      final data = await supabase
          .from(Tables.prescriptions)
          .select(_prescriptionColumns)
          .eq('doctor_id', doctorId!)
          .order('issued_date', ascending: false)
          .limit(limit);
      return (data as List).map((e) => Prescription.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load prescriptions: $e');
    }
  }

  /// Get a single prescription by ID.
  Future<Prescription> getPrescription(String id) async {
    try {
      final data = await supabase
          .from(Tables.prescriptions)
          .select(_prescriptionColumns)
          .eq('id', id)
          .single();
      return Prescription.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load prescription: $e');
    }
  }

  /// Get pending renewal requests for a doctor.
  Future<List<Map<String, dynamic>>> listPendingRenewals(String doctorId) async {
    try {
      final data = await supabase
          .from(Tables.prescriptionRenewals)
          .select(
            'id, status, requested_at, doctor_notes, reviewed_at, '
            'prescriptions(id, diagnosis, status, prescription_items(medication_name, dosage, frequency)), '
            'profiles!prescription_renewals_patient_id_fkey(full_name, avatar_url)',
          )
          .eq('doctor_id', doctorId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load renewals: $e');
    }
  }

  /// Approve or reject a renewal.
  Future<void> updateRenewalStatus(String renewalId, RenewalStatus status, {String? notes}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.value,
        'responded_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (notes != null) {
        updates['doctor_notes'] = notes;
      }

      await supabase
          .from(Tables.prescriptionRenewals)
          .update(updates)
          .eq('id', renewalId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to update renewal: $e');
    }
  }

  /// Request a renewal (patient side).
  Future<void> requestRenewal(String prescriptionId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw const AppException(message: 'Not authenticated.');

    try {
      // Look up the prescription to get doctor_id
      final rx = await supabase
          .from(Tables.prescriptions)
          .select('doctor_id')
          .eq('id', prescriptionId)
          .single();

      await supabase.from(Tables.prescriptionRenewals).insert({
        'prescription_id': prescriptionId,
        'patient_id': uid,
        'doctor_id': rx['doctor_id'],
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to request renewal: $e');
    }
  }
}
