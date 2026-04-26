import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/app_constants.dart';

/// Structured result from an OCR pass.
class OcrResult {
  final String rawText;
  final Map<String, dynamic> structuredData;
  final OcrEngine engine;

  const OcrResult({
    required this.rawText,
    required this.structuredData,
    required this.engine,
  });

  /// Merge into a flat JSON map suitable for storing in `medical_records.data`.
  Map<String, dynamic> toDataMap() => {
        'raw_text': rawText,
        'ocr_engine': engine.value,
        ...structuredData,
      };
}

/// Service that abstracts OCR behind two engines: Gemini and Tesseract.
///
/// Files stay on-device; no cloud storage upload is performed.
class OcrService {
  /// Reads the model name from the .env file, defaulting to gemini-1.5-flash.
  static String get _modelName =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

  static const String _extractionPrompt = '''
You are a medical document parser. Extract information from the document image below.
Return a single valid JSON object (no markdown, no explanation) with these keys
(set the value to null if not found in the document):
{
  "medication_name": "<string or null>",
  "dosage": "<string or null>",
  "doctor_name": "<string or null>",
  "patient_name": "<string or null>",
  "date": "<ISO-8601 date string or null>",
  "diagnosis": "<string or null>",
  "instructions": "<string or null>",
  "hospital_name": "<string or null>",
  "raw_text": "<full verbatim text from the document>"
}
''';

  // ────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────

  /// Extract medical data from an image using [engine].
  ///
  /// Throws an [OcrException] on failure.
  Future<OcrResult> extractFromImage(File imageFile, OcrEngine engine) async {
    switch (engine) {
      case OcrEngine.gemini:
        return _geminiImage(imageFile);
      case OcrEngine.tesseract:
        return _tesseract(imageFile);
    }
  }

  /// Extract medical data from a PDF file.
  ///
  /// Tesseract cannot process PDFs — Gemini is always used regardless of
  /// [engine]. Callers should surface this constraint in the UI.
  Future<OcrResult> extractFromPdf(File pdfFile, OcrEngine engine) {
    // Tesseract cannot natively read PDFs, so we always route through Gemini.
    return _geminiPdf(pdfFile);
  }

  // ────────────────────────────────────────────────────────────
  // Gemini Vision — image
  // ────────────────────────────────────────────────────────────

  Future<OcrResult> _geminiImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final mime = _mimeForPath(imageFile.path);
    final content = [
      Content.multi([
        TextPart(_extractionPrompt),
        DataPart(mime, bytes),
      ]),
    ];
    return _callGeminiWithRetry(content);
  }

  // ────────────────────────────────────────────────────────────
  // Gemini Vision — PDF
  // ────────────────────────────────────────────────────────────

  Future<OcrResult> _geminiPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final content = [
      Content.multi([
        TextPart(_extractionPrompt),
        DataPart('application/pdf', bytes),
      ]),
    ];
    return _callGeminiWithRetry(content);
  }

  // ────────────────────────────────────────────────────────────
  // Gemini key-rotation retry
  // ────────────────────────────────────────────────────────────

  /// Tries every GEMINI_API_KEY / GEMINI_API_KEY_1..5 in order.
  /// Moves to the next key whenever a key is suspended, quota-exceeded,
  /// or otherwise rejected; other errors are re-thrown immediately.
  Future<OcrResult> _callGeminiWithRetry(List<Content> content) async {
    final keys = _getApiKeys();
    if (keys.isEmpty) {
      throw const OcrException(
        'No Gemini API keys found in .env. '
        'Add GEMINI_API_KEY (or GEMINI_API_KEY_1..5) to use Gemini OCR.',
      );
    }

    Object? lastError;
    for (final key in keys) {
      try {
        final model = GenerativeModel(model: _modelName, apiKey: key);
        final response = await model.generateContent(content);
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw const OcrException('Gemini returned an empty response.');
        }
        return _parseGeminiJson(text, OcrEngine.gemini);
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        // Rotate to the next key for account/quota issues.
        if (msg.contains('suspend') ||
            msg.contains('quota') ||
            msg.contains('rate') ||
            msg.contains('unauthorized') ||
            msg.contains('api_key') ||
            msg.contains('consumer')) {
          continue;
        }
        // Any other error (network, parse) — rethrow immediately.
        rethrow;
      }
    }
    throw OcrException(
      'All Gemini API keys failed. Last error: $lastError',
    );
  }

  /// Collects all non-empty API keys from .env in priority order.
  List<String> _getApiKeys() {
    const envKeys = [
      'GEMINI_API_KEY',
      'GEMINI_API_KEY_1',
      'GEMINI_API_KEY_2',
      'GEMINI_API_KEY_3',
      'GEMINI_API_KEY_4',
      'GEMINI_API_KEY_5',
    ];
    return [
      for (final k in envKeys)
        if (dotenv.env[k]?.isNotEmpty == true) dotenv.env[k]!,
    ];
  }

  // ────────────────────────────────────────────────────────────
  // Tesseract — local offline OCR
  // ────────────────────────────────────────────────────────────

  Future<OcrResult> _tesseract(File imageFile) async {
    try {
      final rawText = await FlutterTesseractOcr.extractText(
        imageFile.path,
        language: 'eng',
        args: {'preserve_interword_spaces': '1'},
      );

      final trimmed = rawText.trim();
      if (trimmed.isEmpty) {
        throw const OcrException('Tesseract extracted no text from the image.');
      }

      return OcrResult(
        rawText: trimmed,
        structuredData: {'raw_text': trimmed},
        engine: OcrEngine.tesseract,
      );
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Tesseract OCR failed: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────


  /// Strip markdown fences and decode the JSON Gemini returns.
  OcrResult _parseGeminiJson(String raw, OcrEngine engine) {
    String cleaned = raw.trim();

    // Remove ```json ... ``` fences if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'^```[a-zA-Z]*\n?', multiLine: false), '')
          .replaceAll(RegExp(r'\n?```$', multiLine: false), '')
          .trim();
    }

    try {
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final rawText = decoded['raw_text'] as String? ?? cleaned;
      return OcrResult(
        rawText: rawText,
        structuredData: decoded,
        engine: engine,
      );
    } catch (_) {
      // JSON parsing failed — keep everything as raw text
      return OcrResult(
        rawText: cleaned,
        structuredData: {'raw_text': cleaned},
        engine: engine,
      );
    }
  }

  String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

/// Typed exception thrown by [OcrService].
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
