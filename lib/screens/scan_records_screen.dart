import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/error_handler.dart';
import '../providers/medical_record_provider.dart';
import '../widgets/voxmed_card.dart';

class ScanRecordsScreen extends ConsumerStatefulWidget {
  const ScanRecordsScreen({super.key});

  @override
  ConsumerState<ScanRecordsScreen> createState() => _ScanRecordsScreenState();
}

class _ScanRecordsScreenState extends ConsumerState<ScanRecordsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  RecordType? _selectedRecordType;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      setState(() => _selectedFile = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadRecord() async {
    if (_selectedFile == null) {
      showErrorSnackBar(context, 'Please select an image first.');
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

    setState(() => _isUploading = true);
    try {
      final fileName = _selectedFile!.path.split(Platform.pathSeparator).last;
      final result = await ref.read(medicalRecordsProvider.notifier).uploadRecord(
            file: _selectedFile!,
            fileName: fileName,
            title: title,
            recordType: _selectedRecordType!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (!mounted) return;
      if (result == null) {
        final state = ref.read(medicalRecordsProvider);
        final message = state.error?.message ?? 'Upload failed. Please try again.';
        showErrorSnackBar(context, message);
        return;
      }

      showSuccessSnackBar(context, 'Record uploaded successfully.');
      ref.invalidate(recentMedicalRecordsProvider);
      context.go(AppRoutes.passport);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
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
            const SizedBox(height: 8),
            Text(
              'Capture or select a medical document and securely store it in your health passport.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _buildImageSelector(),
            if (_selectedFile != null) ...[
              const SizedBox(height: 14),
              _buildImagePreview(),
            ],
            const SizedBox(height: 20),
            _buildRecordForm(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadRecord,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save to Health Passport'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take photo'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Choose from gallery'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_selectedFile != null)
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('Clear selection'),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedFile = null);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
            ),
            child: const Icon(Icons.document_scanner, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile == null ? 'Select Document' : 'Change Document',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to use camera or gallery',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
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
                  (type) => DropdownMenuItem<RecordType>(
                    value: type,
                    child: Text(type.value.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedRecordType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g. CBC Report - March 2026',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
            ),
          ),
        ],
      ),
    );
  }
}
