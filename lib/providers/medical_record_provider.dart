import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/medical_record.dart';
import '../repositories/medical_record_repository.dart';
import '../repositories/ocr_service.dart';

/// Provides the MedicalRecordRepository instance.
final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((ref) {
  return MedicalRecordRepository();
});

/// Persisted OCR engine preference (survives hot-reload; reset per session).
final ocrEngineProvider = StateProvider<OcrEngine>((ref) => OcrEngine.gemini);

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

  /// Local-first save: copy file to device, run OCR, persist metadata to DB.
  ///
  /// No Supabase Storage upload is performed.
  /// Returns the created [MedicalRecord] or null on failure.
  Future<MedicalRecord?> saveRecordLocally({
    required File file,
    required String fileName,
    required String title,
    required RecordType recordType,
    required OcrEngine ocrEngine,
    String? description,
    DateTime? recordDate,
    bool isPdf = false,
  }) async {
    try {
      // 1. Copy file into app documents directory
      final relPath = await _repository.saveFileLocally(file, fileName);

      // 2. Run OCR (non-blocking on failure)
      OcrResult? ocrResult;
      try {
        ocrResult = await _repository.runOcr(file, ocrEngine, isPdf: isPdf);
      } catch (_) {
        // OCR is non-critical — record is still saved without extracted data
      }

      // 3. Persist to database
      final record = await _repository.createRecord(
        title: title,
        recordType: recordType,
        description: description,
        localRelativePath: relPath,
        isPdf: isPdf,
        ocrResult: ocrResult,
        recordDate: recordDate,
      );

      // 4. Prepend to in-memory list
      state = state.copyWith(records: [record, ...state.records]);
      return record;
    } on AppException catch (e) {
      state = state.copyWith(error: e);
      return null;
    } catch (e) {
      state = state.copyWith(
        error: AppException(message: 'Failed to save record: $e'),
      );
      return null;
    }
  }

  /// Delete a medical record (removes local file + DB row).
  Future<void> deleteRecord(String recordId) async {
    try {
      await _repository.deleteRecord(recordId);
      state = state.copyWith(
        records: state.records.where((r) => r.id != recordId).toList(),
      );
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

/// Recent medical records for the current patient (for dashboard / passport).
final recentMedicalRecordsProvider = FutureProvider<List<MedicalRecord>>((ref) async {
  final repository = ref.read(medicalRecordRepositoryProvider);
  return repository.listByUser(limit: 10);
});

/// Resolves the absolute path for a [MedicalRecord] that has a local file.
final localFilePathProvider =
    FutureProvider.family<String?, MedicalRecord>((ref, record) async {
  final rel = record.localFilePath;
  if (rel == null) return null;
  final repository = ref.read(medicalRecordRepositoryProvider);
  return repository.resolveLocalFilePath(rel);
});

// ── Backward-compat shim (old uploadRecord callers) ──────────────────────────

extension MedicalRecordsNotifierCompat on MedicalRecordsNotifier {
  /// Deprecated: use [saveRecordLocally] instead.
  ///
  /// Kept to avoid breaking any callers while migration is in progress.
  @Deprecated('Use saveRecordLocally — files are kept on-device, not uploaded.')
  Future<MedicalRecord?> uploadRecord({
    required File file,
    required String fileName,
    required String title,
    required RecordType recordType,
    String? description,
    DateTime? recordDate,
  }) {
    final ext = p.extension(fileName).toLowerCase();
    final isPdf = ext == '.pdf';
    return saveRecordLocally(
      file: file,
      fileName: fileName,
      title: title,
      recordType: recordType,
      ocrEngine: OcrEngine.gemini,
      description: description,
      recordDate: recordDate,
      isPdf: isPdf,
    );
  }
}


