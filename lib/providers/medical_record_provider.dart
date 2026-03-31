import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medical_record.dart';
import '../repositories/medical_record_repository.dart';

/// Provides the MedicalRecordRepository instance.
final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((ref) {
  return MedicalRecordRepository();
});

/// State for medical records list with loading/error handling.
class MedicalRecordsState {
  final List<MedicalRecord> records;
  final bool isLoading;
  final AppException? error;

  const MedicalRecordsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  MedicalRecordsState copyWith({
    List<MedicalRecord>? records,
    bool? isLoading,
    AppException? error,
  }) {
    return MedicalRecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing medical records state.
class MedicalRecordsNotifier extends StateNotifier<MedicalRecordsState> {
  final MedicalRecordRepository _repository;

  MedicalRecordsNotifier(this._repository) : super(const MedicalRecordsState());

  /// Fetch medical records for current user.
  Future<void> fetchRecords({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _repository.listByUser(limit: limit, offset: offset);
      state = state.copyWith(records: records, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Upload a record file and create a record in database.
  Future<MedicalRecord?> uploadRecord({
    required File file,
    required String fileName,
    required String title,
    required RecordType recordType,
    String? description,
    DateTime? recordDate,
  }) async {
    try {
      // Upload file to storage
      final fileUrl = await _repository.uploadRecordFile(
        file: file,
        fileName: fileName,
        bucket: 'medical-records',
      );

      // Extract data via OCR (async, non-blocking)
      Map<String, dynamic>? extractedData;
      try {
        extractedData = await _repository.extractDataFromRecord(fileUrl);
      } catch (e) {
        print('OCR extraction failed (non-critical): $e'); // ignore: avoid_print
      }

      // Create record in database
      final record = await _repository.createRecord(
        title: title,
        recordType: recordType,
        description: description,
        fileUrl: fileUrl,
        extractedData: extractedData,
        recordDate: recordDate,
      );

      // Add to local state
      state = state.copyWith(
        records: [record, ...state.records],
      );

      return record;
    } on AppException catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }

  /// Delete a medical record.
  Future<void> deleteRecord(String recordId) async {
    try {
      await _repository.deleteRecord(recordId);

      // Remove from local state
      final updatedRecords =
          state.records.where((r) => r.id != recordId).toList();
      state = state.copyWith(records: updatedRecords);
    } on AppException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for medical records notifier.
final medicalRecordsProvider =
    StateNotifierProvider<MedicalRecordsNotifier, MedicalRecordsState>((ref) {
  final repository = ref.watch(medicalRecordRepositoryProvider);
  return MedicalRecordsNotifier(repository);
});

/// Provider for async medical record lookup by ID.
final medicalRecordDetailProvider =
    FutureProvider.family<MedicalRecord, String>((ref, recordId) async {
  final repository = ref.watch(medicalRecordRepositoryProvider);
  return repository.getRecord(recordId);
});
