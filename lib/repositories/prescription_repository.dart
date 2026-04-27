import 'dart:async';
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

  /// Approve, reject, or call for follow-up on a renewal.
  Future<void> updateRenewalStatus(
    String renewalId,
    RenewalStatus status, {
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.value,
        'responded_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (notes != null) updates['doctor_notes'] = notes;

      // Fetch the renewal row to get patient_id for the notification.
      final row = await supabase
          .from(Tables.prescriptionRenewals)
          .select('patient_id, prescription_id')
          .eq('id', renewalId)
          .maybeSingle();

      await supabase
          .from(Tables.prescriptionRenewals)
          .update(updates)
          .eq('id', renewalId);

      if (row != null) {
        unawaited(_notifyPatientOfRenewalResponse(
          patientId: row['patient_id'] as String,
          prescriptionId: row['prescription_id'] as String,
          status: status,
          notes: notes,
        ));
      }
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to update renewal: $e');
    }
  }

  Future<void> _notifyPatientOfRenewalResponse({
    required String patientId,
    required String prescriptionId,
    required RenewalStatus status,
    String? notes,
  }) async {
    try {
      late String title;
      late String body;
      late String type;

      switch (status) {
        case RenewalStatus.approved:
          title = 'Prescription Renewed';
          body = 'Your doctor approved your prescription renewal. Your medication is ready.';
          type = 'renewal_approved';
        case RenewalStatus.rejected:
          title = 'Renewal Rejected';
          body = notes != null && notes.isNotEmpty
              ? 'Renewal denied: $notes'
              : 'Your doctor declined the prescription renewal request.';
          type = 'renewal_rejected';
        case RenewalStatus.followUp:
          title = 'Follow-Up Required';
          body = notes != null && notes.isNotEmpty
              ? 'Your doctor needs a follow-up: $notes'
              : 'Your doctor has requested a follow-up before renewing your prescription.';
          type = 'renewal_follow_up';
        default:
          return;
      }

      await supabase.from(Tables.notifications).insert({
        'user_id': patientId,
        'type': type,
        'title': title,
        'body': body,
        'data': {'prescription_id': prescriptionId},
        'is_read': false,
      });
    } catch (_) {}
  }

  /// Request a renewal (patient side).
  Future<void> requestRenewal(String prescriptionId, {String? reason}) async {
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
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

      // Notify doctor in background.
      unawaited(_notifyDoctorOfRenewalRequest(
        doctorId: rx['doctor_id'] as String,
        prescriptionId: prescriptionId,
      ));
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to request renewal: $e');
    }
  }

  Future<void> _notifyDoctorOfRenewalRequest({
    required String doctorId,
    required String prescriptionId,
  }) async {
    try {
      // Resolve doctor profile_id
      final doctorRow = await supabase
          .from(Tables.doctors)
          .select('profile_id')
          .eq('id', doctorId)
          .maybeSingle();
      if (doctorRow == null) return;
      final doctorUserId = doctorRow['profile_id'] as String?;
      if (doctorUserId == null) return;

      // Resolve patient name
      final patientProfile = await supabase
          .from(Tables.profiles)
          .select('full_name')
          .eq('id', supabase.auth.currentUser!.id)
          .maybeSingle();
      final patientName = patientProfile?['full_name'] as String? ?? 'A patient';

      await supabase.from(Tables.notifications).insert({
        'user_id': doctorUserId,
        'type': 'renewal_request',
        'title': 'New Renewal Request',
        'body': '$patientName has requested a prescription renewal.',
        'data': {'prescription_id': prescriptionId},
        'is_read': false,
      });
    } catch (_) {}
  }

  /// Create a new prescription with medication items (doctor writes prescription).
  Future<Prescription> createPrescriptionWithItems({
    required String patientId,
    required String doctorId,
    String? appointmentId,
    String? diagnosis,
    String? notes,
    DateTime? validUntil,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final rxData = await supabase
          .from(Tables.prescriptions)
          .insert({
            'patient_id': patientId,
            'doctor_id': doctorId,
            if (appointmentId != null) 'appointment_id': appointmentId,
            if (diagnosis != null) 'diagnosis': diagnosis,
            if (notes != null) 'notes': notes,
            'status': 'active',
            'issued_date': DateTime.now().toIso8601String().split('T').first,
            if (validUntil != null)
              'valid_until': validUntil.toIso8601String().split('T').first,
          })
          .select('id')
          .single();

      final rxId = rxData['id'] as String;
      if (items.isNotEmpty) {
        final itemsToInsert = items
            .map((item) => {...item, 'prescription_id': rxId})
            .toList();
        await supabase.from(Tables.prescriptionItems).insert(itemsToInsert);
      }

      return getPrescription(rxId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create prescription: $e');
    }
  }
}
