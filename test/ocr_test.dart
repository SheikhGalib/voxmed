// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';
import 'package:voxmed/models/medical_record.dart';
import 'package:voxmed/repositories/ocr_service.dart';

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── OcrEngine enum ──────────────────────────────────────────────────────────
  group('OcrEngine enum', () {
    test('values are gemini and tesseract', () {
      expect(OcrEngine.values.length, 2);
      expect(OcrEngine.values, containsAll([OcrEngine.gemini, OcrEngine.tesseract]));
    });

    test('value getter returns name', () {
      expect(OcrEngine.gemini.value, 'gemini');
      expect(OcrEngine.tesseract.value, 'tesseract');
    });

    test('label getter returns human-readable string', () {
      expect(OcrEngine.gemini.label, 'Gemini AI');
      expect(OcrEngine.tesseract.label, 'Tesseract (Offline)');
    });

    test('fromString roundtrips', () {
      expect(OcrEngine.fromString('gemini'), OcrEngine.gemini);
      expect(OcrEngine.fromString('tesseract'), OcrEngine.tesseract);
    });

    test('fromString defaults to gemini for unknown value', () {
      expect(OcrEngine.fromString('unknown'), OcrEngine.gemini);
    });
  });

  // ── DocumentSourceType ──────────────────────────────────────────────────────
  group('DocumentSourceType', () {
    test('isPdf only for pdfFile', () {
      expect(DocumentSourceType.pdfFile.isPdf, isTrue);
      expect(DocumentSourceType.camera.isPdf, isFalse);
      expect(DocumentSourceType.gallery.isPdf, isFalse);
    });

    test('isImage for camera and gallery', () {
      expect(DocumentSourceType.camera.isImage, isTrue);
      expect(DocumentSourceType.gallery.isImage, isTrue);
      expect(DocumentSourceType.pdfFile.isImage, isFalse);
    });
  });

  // ── OcrResult ───────────────────────────────────────────────────────────────
  group('OcrResult', () {
    test('toDataMap includes engine and raw_text', () {
      const result = OcrResult(
        rawText: 'Sample text',
        structuredData: {'raw_text': 'Sample text', 'medication_name': 'Ibuprofen'},
        engine: OcrEngine.gemini,
      );

      final map = result.toDataMap();
      expect(map['ocr_engine'], 'gemini');
      expect(map['raw_text'], 'Sample text');
      expect(map['medication_name'], 'Ibuprofen');
    });

    test('toDataMap with Tesseract engine', () {
      const result = OcrResult(
        rawText: 'Raw text only',
        structuredData: {'raw_text': 'Raw text only'},
        engine: OcrEngine.tesseract,
      );

      final map = result.toDataMap();
      expect(map['ocr_engine'], 'tesseract');
      expect(map['raw_text'], 'Raw text only');
    });

    test('structuredData is preserved in toDataMap', () {
      const result = OcrResult(
        rawText: 'Some text',
        structuredData: {
          'raw_text': 'Some text',
          'doctor_name': 'Dr. Smith',
          'dosage': '500mg',
          'diagnosis': 'Flu',
        },
        engine: OcrEngine.gemini,
      );

      final map = result.toDataMap();
      expect(map['doctor_name'], 'Dr. Smith');
      expect(map['dosage'], '500mg');
      expect(map['diagnosis'], 'Flu');
    });
  });

  // ── OcrException ────────────────────────────────────────────────────────────
  group('OcrException', () {
    test('toString includes message', () {
      const e = OcrException('Something went wrong');
      expect(e.toString(), contains('Something went wrong'));
    });

    test('is an Exception', () {
      const e = OcrException('test');
      expect(e, isA<Exception>());
    });
  });

  // ── OcrService — OcrResult construction ────────────────────────────────────
  group('OcrService — OcrResult construction', () {
    test('OcrResult with complete structured data toDataMap is correct', () {
      const result = OcrResult(
        rawText: 'Ibuprofen 400mg twice daily',
        structuredData: {
          'raw_text': 'Ibuprofen 400mg twice daily',
          'medication_name': 'Ibuprofen',
          'dosage': '400mg',
          'instructions': 'twice daily',
          'doctor_name': null,
          'patient_name': null,
        },
        engine: OcrEngine.gemini,
      );

      final map = result.toDataMap();
      expect(map['medication_name'], 'Ibuprofen');
      expect(map['dosage'], '400mg');
      expect(map['ocr_engine'], 'gemini');
    });
  });

  // ── MedicalRecord convenience getters ───────────────────────────────────────
  group('MedicalRecord OCR getters', () {
    MedicalRecord makeRecord({Map<String, dynamic>? data}) {
      return MedicalRecord(
        id: 'test-id',
        patientId: 'patient-id',
        recordType: RecordType.prescription,
        title: 'Test Record',
        ocrExtracted: data != null,
        data: data,
        createdAt: DateTime(2026, 4, 26),
        updatedAt: DateTime(2026, 4, 26),
      );
    }

    test('localFilePath returns null when data is null', () {
      final r = makeRecord();
      expect(r.localFilePath, isNull);
    });

    test('localFilePath returns value from data map', () {
      final r = makeRecord(data: {
        'local_file_path': 'records/12345_scan.jpg',
        'file_type': 'image',
      });
      expect(r.localFilePath, 'records/12345_scan.jpg');
    });

    test('ocrEngine returns null when data has no ocr_engine', () {
      final r = makeRecord(data: {'raw_text': 'some text'});
      expect(r.ocrEngine, isNull);
    });

    test('ocrEngine returns OcrEngine.gemini from data', () {
      final r = makeRecord(data: {'ocr_engine': 'gemini', 'raw_text': 'text'});
      expect(r.ocrEngine, OcrEngine.gemini);
    });

    test('ocrEngine returns OcrEngine.tesseract from data', () {
      final r = makeRecord(data: {'ocr_engine': 'tesseract', 'raw_text': 'text'});
      expect(r.ocrEngine, OcrEngine.tesseract);
    });

    test('ocrRawText returns null when no data', () {
      final r = makeRecord();
      expect(r.ocrRawText, isNull);
    });

    test('ocrRawText returns extracted text', () {
      final r = makeRecord(data: {'raw_text': 'Patient: John\nRx: Amoxicillin'});
      expect(r.ocrRawText, 'Patient: John\nRx: Amoxicillin');
    });

    test('isPdf returns false when no data', () {
      final r = makeRecord();
      expect(r.isPdf, isFalse);
    });

    test('isPdf returns true when file_type is pdf', () {
      final r = makeRecord(data: {'file_type': 'pdf'});
      expect(r.isPdf, isTrue);
    });

    test('isPdf returns false when file_type is image', () {
      final r = makeRecord(data: {'file_type': 'image'});
      expect(r.isPdf, isFalse);
    });

    test('ocrExtracted flag is true when data contains OCR result', () {
      final r = makeRecord(data: {
        'raw_text': 'text',
        'ocr_engine': 'gemini',
      });
      expect(r.ocrExtracted, isTrue);
    });

    test('MedicalRecord.fromJson parses data JSONB with OCR fields', () {
      final json = {
        'id': 'abc-123',
        'patient_id': 'p-001',
        'doctor_id': null,
        'appointment_id': null,
        'record_type': 'prescription',
        'title': 'Amoxicillin Rx',
        'description': null,
        'file_url': null,
        'ocr_extracted': true,
        'record_date': null,
        'created_at': '2026-04-26T10:00:00Z',
        'updated_at': '2026-04-26T10:00:00Z',
        'data': {
          'local_file_path': 'records/1714129200000_rx.jpg',
          'file_type': 'image',
          'ocr_engine': 'gemini',
          'raw_text': 'Amoxicillin 500mg',
          'medication_name': 'Amoxicillin',
          'dosage': '500mg',
        },
      };

      final record = MedicalRecord.fromJson(json);
      expect(record.ocrExtracted, isTrue);
      expect(record.ocrEngine, OcrEngine.gemini);
      expect(record.localFilePath, 'records/1714129200000_rx.jpg');
      expect(record.ocrRawText, 'Amoxicillin 500mg');
      expect(record.isPdf, isFalse);
      expect(record.data?['medication_name'], 'Amoxicillin');
    });

    test('MedicalRecord.fromJson handles missing data field', () {
      final json = {
        'id': 'abc-456',
        'patient_id': 'p-002',
        'doctor_id': null,
        'appointment_id': null,
        'record_type': 'lab_result',
        'title': 'CBC Report',
        'description': null,
        'file_url': null,
        'ocr_extracted': false,
        'record_date': null,
        'data': null,
        'created_at': '2026-04-26T10:00:00Z',
        'updated_at': '2026-04-26T10:00:00Z',
      };

      final record = MedicalRecord.fromJson(json);
      expect(record.data, isNull);
      expect(record.ocrEngine, isNull);
      expect(record.localFilePath, isNull);
      expect(record.ocrRawText, isNull);
    });
  });

  // ── RecordType enum (existing coverage extension) ───────────────────────────
  group('RecordType enum (OCR context)', () {
    test('all types have valid values', () {
      for (final t in RecordType.values) {
        expect(t.value, isNotEmpty);
      }
    });

    test('fromString roundtrips for all types', () {
      for (final t in RecordType.values) {
        expect(RecordType.fromString(t.value), t);
      }
    });
  });
}
