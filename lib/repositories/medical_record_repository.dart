// ignore_for_file: use_null_aware_elements
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medical_record.dart';
import 'ocr_service.dart';

/// Repository for medical record data access.
///
/// Files are kept **local** to the device. The OCR result (structured data)
/// is stored in the `data` JSONB column of `medical_records`; no upload to
/// Supabase Storage is performed.
class MedicalRecordRepository {
  final OcrService _ocr;

  MedicalRecordRepository({OcrService? ocrService})
      : _ocr = ocrService ?? OcrService();

  // ── Read operations ─────────────────────────────────────────────────────────

  /// List all medical records for the current user (patient).
  Future<List<MedicalRecord>> listByUser({int limit = 50, int offset = 0}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw AppException(message: 'User not authenticated');

      final data = await supabase
          .from(Tables.medicalRecords)
          .select(
            'id, patient_id, doctor_id, appointment_id, record_type, title, description, data, file_url, ocr_extracted, record_date, created_at, updated_at',
          )
          .eq('patient_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((e) => MedicalRecord.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load medical records: $e');
    }
  }

  /// Get a single record by ID.
  Future<MedicalRecord> getRecord(String recordId) async {
    try {
      final data = await supabase
          .from(Tables.medicalRecords)
          .select(
            'id, patient_id, doctor_id, appointment_id, record_type, title, description, data, file_url, ocr_extracted, record_date, created_at, updated_at',
          )
          .eq('id', recordId)
          .single();
      return MedicalRecord.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load medical record: $e');
    }
  }

  /// List medical records for a specific patient (doctor access).
  Future<List<MedicalRecord>> listByPatientId(
    String patientId, {
    int limit = 50,
  }) async {
    try {
      final data = await supabase
          .from(Tables.medicalRecords)
          .select(
            'id, patient_id, doctor_id, appointment_id, record_type, title, description, data, file_url, ocr_extracted, record_date, created_at, updated_at',
          )
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((e) => MedicalRecord.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load patient records: $e');
    }
  }

  // ── Local file storage ───────────────────────────────────────────────────────

  /// Copy [file] into the app's documents directory under `records/`.
  ///
  /// Returns the relative path (e.g. `records/1234_file.jpg`) so it can be
  /// reconstructed on any future app launch via [resolveLocalFilePath].
  Future<String> saveFileLocally(File file, String originalName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final recordsDir = Directory(p.join(docsDir.path, 'records'));
    if (!recordsDir.existsSync()) {
      recordsDir.createSync(recursive: true);
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = originalName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final destPath = p.join(recordsDir.path, '${stamp}_$safeName');
    await file.copy(destPath);
    // Store relative path so it works after app reinstall to same path prefix
    return p.join('records', '${stamp}_$safeName');
  }

  /// Resolve a relative path (from [saveFileLocally]) back to an absolute path.
  Future<String> resolveLocalFilePath(String relativePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, relativePath);
  }

  // ── OCR ─────────────────────────────────────────────────────────────────────

  /// Run OCR on a local [file] using the specified [engine].
  ///
  /// For PDFs, Gemini is always used regardless of [engine].
  /// Returns null if OCR fails non-critically.
  Future<OcrResult?> runOcr(
    File file,
    OcrEngine engine, {
    bool isPdf = false,
  }) async {
    try {
      if (isPdf) return await _ocr.extractFromPdf(file, engine);
      return await _ocr.extractFromImage(file, engine);
    } on OcrException catch (e) {
      // OCR failure is non-critical — caller decides whether to propagate
      print('OCR non-critical failure: $e'); // ignore: avoid_print
      return null;
    } catch (e) {
      print('OCR unexpected error: $e'); // ignore: avoid_print
      return null;
    }
  }

  // ── Write operations ─────────────────────────────────────────────────────────

  /// Create a new medical record in the database.
  ///
  /// Pass [localRelativePath] and [ocrResult] from the local-first save flow.
  /// No Supabase Storage upload is performed.
  Future<MedicalRecord> createRecord({
    required String title,
    required RecordType recordType,
    String? description,
    String? localRelativePath,
    bool isPdf = false,
    OcrResult? ocrResult,
    DateTime? recordDate,
    String? doctorId,
    String? appointmentId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw AppException(message: 'User not authenticated');

      // Build data JSONB: local path metadata + OCR output
      final dataMap = <String, dynamic>{
        if (localRelativePath != null) 'local_file_path': localRelativePath,
        'file_type': isPdf ? 'pdf' : 'image',
        if (ocrResult != null) ...ocrResult.toDataMap(),
      };

      final toInsert = <String, dynamic>{
        'patient_id': userId,
        'record_type': recordType.value,
        'title': title,
        'ocr_extracted': ocrResult != null,
        'data': dataMap,
        if (doctorId != null) 'doctor_id': doctorId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (description != null) 'description': description,
        if (recordDate != null)
          'record_date': recordDate.toIso8601String().split('T').first,
      };

      final result = await supabase
          .from(Tables.medicalRecords)
          .insert(toInsert)
          .select(
            'id, patient_id, doctor_id, appointment_id, record_type, title, description, data, file_url, ocr_extracted, record_date, created_at, updated_at',
          )
          .single();

      return MedicalRecord.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create medical record: $e');
    }
  }

  /// Delete a medical record (and its local file if present).
  Future<void> deleteRecord(String recordId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw AppException(message: 'User not authenticated');

      final row = await supabase
          .from(Tables.medicalRecords)
          .select('patient_id, data')
          .eq('id', recordId)
          .single();

      if (row['patient_id'] != userId) {
        throw AppException(message: 'Unauthorized: Cannot delete this record');
      }

      // Attempt to clean up local file
      final dataField = row['data'] as Map<String, dynamic>?;
      final relPath = dataField?['local_file_path'] as String?;
      if (relPath != null) {
        try {
          final absPath = await resolveLocalFilePath(relPath);
          final localFile = File(absPath);
          if (localFile.existsSync()) localFile.deleteSync();
        } catch (_) {
          // Non-critical: DB row deletion proceeds even if file cleanup fails
        }
      }

      await supabase.from(Tables.medicalRecords).delete().eq('id', recordId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to delete medical record: $e');
    }
  }
}


