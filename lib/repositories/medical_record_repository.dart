// ignore_for_file: use_null_aware_elements
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medical_record.dart';

/// Repository for medical record data access and file uploads.
class MedicalRecordRepository {
  /// List all medical records for the current user (patient).
  Future<List<MedicalRecord>> listByUser({int limit = 50, int offset = 0}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(message: 'User not authenticated');
      }

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

  /// Create a new medical record.
  Future<MedicalRecord> createRecord({
    required String title,
    required RecordType recordType,
    String? description,
    String? fileUrl,
    Map<String, dynamic>? extractedData,
    DateTime? recordDate,
    String? doctorId,
    String? appointmentId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(message: 'User not authenticated');
      }

      final toInsert = <String, dynamic>{
        'patient_id': userId,
        'record_type': recordType.value,
        'title': title,
        'ocr_extracted': extractedData != null,
        if (doctorId != null) 'doctor_id': doctorId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (description != null) 'description': description,
        if (fileUrl != null) 'file_url': fileUrl,
        if (extractedData != null) 'data': extractedData,
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

  /// Upload a medical record file to Supabase Storage.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadRecordFile({
    required File file,
    required String fileName,
    required String bucket,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(message: 'User not authenticated');
      }

      final filePath = '$userId/records/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Upload file
      await supabase.storage.from(bucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final url = supabase.storage.from(bucket).getPublicUrl(filePath);
      return url;
    } catch (e) {
      throw AppException(message: 'Failed to upload file: $e');
    }
  }

  /// Call Gemini OCR Edge Function to extract data from file URL.
  /// Assumes Edge Function "gemini-ocr" exists in Supabase.
  Future<Map<String, dynamic>?> extractDataFromRecord(String fileUrl) async {
    try {
      final response = await supabase.functions.invoke(
        'gemini-ocr',
        body: {'fileUrl': fileUrl},
      );
      final payload = response.data;

      // FunctionResponse returns data as dynamic, handle gracefully
      if (payload is Map && payload['success'] == true) {
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('OCR extraction failed (non-critical): $e'); // ignore: avoid_print
      return null; // Gracefully handle OCR failures
    }
  }

  /// Delete a medical record.
  Future<void> deleteRecord(String recordId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(message: 'User not authenticated');
      }

      // Verify ownership
      final record = await supabase
          .from(Tables.medicalRecords)
          .select('patient_id')
          .eq('id', recordId)
          .single();

      if (record['patient_id'] != userId) {
        throw AppException(message: 'Unauthorized: Cannot delete this record');
      }

      await supabase.from(Tables.medicalRecords).delete().eq('id', recordId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to delete medical record: $e');
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

  /// List medical records for a specific patient (for doctor access).
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
}
