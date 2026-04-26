import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/error_handler.dart';
import '../providers/medical_record_provider.dart';
import '../repositories/ocr_service.dart';
import '../widgets/voxmed_card.dart';

/// Screen for scanning / uploading medical documents.
///
/// Flow:
///   1. Pick a document (camera, gallery, or PDF from files).
///   2. Choose OCR engine (Gemini AI or Tesseract offline).
///   3. Tap "Extract Medical Data" — runs OCR locally, shows result.
///   4. Review / edit details and tap "Save to Health Passport".
///
/// Files are stored **on-device only** — no Supabase Storage upload.
class ScanRecordsScreen extends ConsumerStatefulWidget {
  const ScanRecordsScreen({super.key});

  @override
  ConsumerState<ScanRecordsScreen> createState() => _ScanRecordsScreenState();
}

class _ScanRecordsScreenState extends ConsumerState<ScanRecordsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  bool _isPdf = false;
  RecordType? _selectedRecordType;
  OcrEngine _ocrEngine = OcrEngine.gemini;

  bool _isExtracting = false;
  bool _isSaving = false;
  OcrResult? _ocrResult;
  String? _ocrError;
  bool _showOcrDetails = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── File picking ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked == null || !mounted) return;
      _setFile(File(picked.path), isPdf: false);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final path = result.files.single.path;
      if (path == null) return;
      _setFile(File(path), isPdf: true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick PDF: $e');
    }
  }

  void _setFile(File file, {required bool isPdf}) {
    setState(() {
      _selectedFile = file;
      _isPdf = isPdf;
      _ocrResult = null;
      _ocrError = null;
    });
  }

  // ── OCR ──────────────────────────────────────────────────────────────────────

  Future<void> _runOcr() async {
    if (_selectedFile == null) return;

    setState(() {
      _isExtracting = true;
      _ocrResult = null;
      _ocrError = null;
    });

    try {
      final repo = ref.read(medicalRecordRepositoryProvider);
      final result = await repo.runOcr(_selectedFile!, _ocrEngine, isPdf: _isPdf);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _ocrError = 'No text could be extracted from this document.';
          _isExtracting = false;
        });
        return;
      }

      setState(() {
        _ocrResult = result;
        _isExtracting = false;
        _showOcrDetails = true;
      });

      _autoFillFields(result);
    } on OcrException catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrError = e.message;
        _isExtracting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrError = 'Extraction failed: $e';
        _isExtracting = false;
      });
    }
  }

  void _autoFillFields(OcrResult result) {
    if (_titleController.text.trim().isNotEmpty) return;
    final structured = result.structuredData;
    final suggested = (structured['medication_name'] as String?)?.isNotEmpty == true
        ? structured['medication_name'] as String
        : (structured['diagnosis'] as String?)?.isNotEmpty == true
            ? structured['diagnosis'] as String
            : null;
    if (suggested != null) _titleController.text = suggested;
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _saveRecord() async {
    if (_selectedFile == null) {
      showErrorSnackBar(context, 'Please select a document first.');
      return;
    }
    if (_selectedRecordType == null) {
      showErrorSnackBar(context, 'Please select a record type.');
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showErrorSnackBar(context, 'Please enter a title.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fileName = p.basename(_selectedFile!.path);
      final record = await ref
          .read(medicalRecordsProvider.notifier)
          .saveRecordLocally(
            file: _selectedFile!,
            fileName: fileName,
            title: title,
            recordType: _selectedRecordType!,
            ocrEngine: _ocrEngine,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isPdf: _isPdf,
          );

      if (!mounted) return;
      if (record == null) {
        final errMsg = ref.read(medicalRecordsProvider).error?.message ??
            'Save failed. Please try again.';
        showErrorSnackBar(context, errMsg);
        return;
      }

      showSuccessSnackBar(context, 'Record saved to Health Passport.');
      ref.invalidate(recentMedicalRecordsProvider);
      context.go(AppRoutes.passport);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scan Medical Records',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDocumentPicker(),
            if (_selectedFile != null) ...[
              const SizedBox(height: 14),
              _buildFilePreview(),
              const SizedBox(height: 20),
              _buildOcrEngineSelector(),
              const SizedBox(height: 14),
              _buildExtractButton(),
              if (_isExtracting) ...[
                const SizedBox(height: 16),
                _buildExtractingIndicator(),
              ],
              if (_ocrError != null) ...[
                const SizedBox(height: 14),
                _buildOcrErrorCard(),
              ],
              if (_ocrResult != null) ...[
                const SizedBox(height: 14),
                _buildOcrResultCard(),
              ],
            ],
            const SizedBox(height: 20),
            _buildRecordForm(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload to Health Passport',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Files stay on your device. OCR extracts the key medical details and saves them to your passport.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Document',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pickerButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 10),
              _pickerButton(
                icon: Icons.image_rounded,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 10),
              _pickerButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                onTap: _pickPdf,
                accent: Colors.deepOrange,
              ),
            ],
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear selection'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() {
                _selectedFile = null;
                _ocrResult = null;
                _ocrError = null;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final color = accent ?? AppColors.primary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_isPdf) {
      return VoxmedCard(
        color: Colors.deepOrange.withValues(alpha: 0.07),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.deepOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(_selectedFile!.path),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PDF — Gemini will be used for text extraction',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        _selectedFile!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildOcrEngineSelector() {
    final pdfSuffix = _isPdf ? ' (PDFs always use Gemini)' : '';
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OCR Engine$pdfSuffix',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: OcrEngine.values.map((engine) {
              final selected = _ocrEngine == engine;
              final disabled = _isPdf && engine == OcrEngine.tesseract;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _engineChip(
                    engine: engine,
                    selected: selected,
                    disabled: disabled,
                    onTap: disabled
                        ? null
                        : () => setState(() => _ocrEngine = engine),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _ocrEngine == OcrEngine.gemini
                ? 'Gemini AI — structured extraction, requires internet.'
                : 'Tesseract — runs fully offline, returns raw text.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _engineChip({
    required OcrEngine engine,
    required bool selected,
    required bool disabled,
    VoidCallback? onTap,
  }) {
    final bg = disabled
        ? AppColors.surfaceContainerLow
        : selected
            ? AppColors.primary
            : AppColors.surfaceContainerLow;
    final fg = disabled
        ? AppColors.onSurfaceVariant.withValues(alpha: 0.4)
        : selected
            ? Colors.white
            : AppColors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected && !disabled
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              engine == OcrEngine.gemini ? Icons.auto_awesome : Icons.memory,
              size: 18,
              color: fg,
            ),
            const SizedBox(height: 4),
            Text(
              engine.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: _isExtracting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.document_scanner_rounded),
        label: Text(_ocrResult != null ? 'Re-extract Data' : 'Extract Medical Data'),
        onPressed: _isExtracting ? null : _runOcr,
      ),
    );
  }

  Widget _buildExtractingIndicator() {
    return VoxmedCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _ocrEngine == OcrEngine.gemini
                  ? 'Gemini is reading your document…'
                  : 'Tesseract is extracting text locally…',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrErrorCard() {
    return VoxmedCard(
      color: Colors.red.withValues(alpha: 0.07),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _ocrError!,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrResultCard() {
    final result = _ocrResult!;
    final structured = result.structuredData;

    final fields = <String, String>{};
    for (final key in [
      'patient_name',
      'doctor_name',
      'hospital_name',
      'medication_name',
      'dosage',
      'diagnosis',
      'date',
      'instructions',
    ]) {
      final val = structured[key];
      if (val != null &&
          val.toString().isNotEmpty &&
          val.toString() != 'null') {
        fields[key.replaceAll('_', ' ')] = val.toString();
      }
    }

    return VoxmedCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Extracted via ${result.engine.label}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showOcrDetails
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _showOcrDetails = !_showOcrDetails),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (_showOcrDetails) ...[
            const SizedBox(height: 10),
            ..._buildOcrFields(fields, result),
          ],
        ],
      ),
    );
  }

  /// Returns a list of field rows or a raw-text fallback widget.
  List<Widget> _buildOcrFields(Map<String, String> fields, OcrResult result) {
    if (fields.isNotEmpty) {
      return fields.entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      _capitalize(e.key),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList();
    }
    return [
      Text(
        result.rawText.length > 400
            ? '${result.rawText.substring(0, 400)}…'
            : result.rawText,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.onSurface,
          height: 1.5,
        ),
      ),
    ];
  }

  Widget _buildRecordForm() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Details',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<RecordType>(
            initialValue: _selectedRecordType,
            decoration: const InputDecoration(labelText: 'Record Type *'),
            items: RecordType.values
                .map(
                  (t) => DropdownMenuItem<RecordType>(
                    value: t,
                    child: Text(_capitalize(t.value.replaceAll('_', ' '))),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedRecordType = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g. CBC Report – March 2026',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Description (Optional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRecord,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save to Health Passport'),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

