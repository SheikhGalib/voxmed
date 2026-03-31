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

      if (!mounted || picked == null) {
        return;
      }

      setState(() {
        _selectedFile = File(picked.path);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorSnackBar(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _openPickerSheet() async {
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
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedFile != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear selection'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadRecord() async {
    if (_selectedFile == null) {
      showErrorSnackBar(context, 'Please select a file first.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please enter a title.');
      return;
    }
    if (_selectedRecordType == null) {
      showErrorSnackBar(context, 'Please select a record type.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = _selectedFile!.path.split(RegExp(r'[/\\]')).last;
      final created = await ref.read(medicalRecordsProvider.notifier).uploadRecord(
            file: _selectedFile!,
            fileName: fileName,
            title: _titleController.text.trim(),
            recordType: _selectedRecordType!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      if (created == null) {
        final error = ref.read(medicalRecordsProvider).error;
        showErrorSnackBar(
          context,
          error?.message ?? 'Could not upload record. Please try again.',
        );
        return;
      }

      showSuccessSnackBar(context, 'Record uploaded successfully.');
      context.go(AppRoutes.passport);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorSnackBar(context, 'Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Scan Records',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload your prescriptions, lab reports, or scans to your Health Passport.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              VoxmedCard(
                onTap: _openPickerSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Choose file',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedFile == null
                          ? 'Tap to capture with camera or select from gallery.'
                          : _selectedFile!.path.split(RegExp(r'[/\\]')).last,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedFile!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              VoxmedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record details',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RecordType>(
                      initialValue: _selectedRecordType,
                      items: RecordType.values
                          .map(
                            (type) => DropdownMenuItem<RecordType>(
                              value: type,
                              child: Text(
                                type.value.replaceAll('_', ' '),
                                style: GoogleFonts.inter(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRecordType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Record Type *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadRecord,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
