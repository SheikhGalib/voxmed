import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../providers/medical_record_provider.dart';

class ScanRecordsScreen extends ConsumerStatefulWidget {
  const ScanRecordsScreen({super.key});

  @override
  ConsumerState<ScanRecordsScreen> createState() => _ScanRecordsScreenState();
}

class _ScanRecordsScreenState extends ConsumerState<ScanRecordsScreen> {
  File? _selectedFile;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
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
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (pickedFile != null && mounted) {
        setState(() => _selectedFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _uploadRecord() async {
    if (_selectedFile == null) {
      showErrorSnackBar(context, 'Please select an image');
      return;
    }
    if (_titleController.text.isEmpty) {
      showErrorSnackBar(context, 'Please enter a title');
      return;
    }
    if (_selectedRecordType == null) {
      showErrorSnackBar(context, 'Please select a record type');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final fileName = _selectedFile!.path.split('/').last;
      final result = await ref.read(medicalRecordsProvider.notifier).uploadRecord(
            file: _selectedFile!,
            fileName: fileName,
            title: _titleController.text,
            recordType: _selectedRecordType!,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          );
      if (mounted && result != null) {
        showSuccessSnackBar(context, 'Record uploaded successfully');
        if (mounted) context.go('/passport');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Health Passport',
                style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Digitize your medical history instantly. Our AI extracts key data from prescriptions and reports with surgical precision.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildScanArea(),
            const SizedBox(height: 20),
            _buildOCRTips(),
                _buildImageSelector(),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 20),
                  _buildImagePreview(),
                ],
                const SizedBox(height: 20),
                _buildRecordForm(),
                const SizedBox(height: 20),
            const SizedBox(height: 24),
            _buildFinalizeButton(),
                _buildUploadSection(),
    );
  }

  Widget _buildScanArea() {
    return Container(
      height: 240,
      Widget _buildImageSelector() {
      decoration: BoxDecoration(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take Photo'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('Choose from Gallery'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_selectedFile != null)
                      ListTile(
                        leading: const Icon(Icons.clear),
                        title: const Text('Clear Selection'),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedFile = null);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner corners
            child: _selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(_selectedFile!, fit: BoxFit.cover),
                  )
                : Stack(
            return Positioned(
              top: i < 2 ? 16 : null,
              bottom: i >= 2 ? 16 : null,
              left: i.isEven ? 16 : null,
              right: i.isOdd ? 16 : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border(
                    top: i < 2 ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                    bottom: i >= 2 ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                    left: i.isEven ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                    right: i.isOdd ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                  ),
                ),
              ),
            );
          }),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined, color: AppColors.primary.withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 12),
              Text('Position document here',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
                    Text('Tap to select or capture document',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
            ],
                    Text('Camera or gallery',
        ],
      ),
    );
  }

          ),
  Widget _buildOCRTips() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      Widget _buildImagePreview() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Image', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        );
      }

      Widget _buildRecordForm() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Details', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 12),
            DropdownButton<RecordType>(
              isExpanded: true,
              value: _selectedRecordType,
              hint: Text('Select Record Type', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
              items: RecordType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.name[0].toUpperCase() + type.name.substring(1), style: GoogleFonts.inter(color: AppColors.onSurface)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedRecordType = value),
              underline: Container(height: 1, color: AppColors.outlineVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Record Title *',
                hintText: 'e.g., Blood Test Report',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes about this record',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        );
      }

      Widget _buildUploadSection() {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _uploadRecord,
            child: _isUploading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save to Health Passport'),
          ),
        );
      }
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pro Tips for Best OCR Accuracy',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 14),
          _TipItem(text: 'Ensure document is well-lit, without glare or shadows.'),
          const SizedBox(height: 10),
          _TipItem(text: 'Hold your phone steady, slightly above the document.'),
          const SizedBox(height: 10),
          _TipItem(text: 'Flatten the document to avoid distortions in text.'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('View Help Guide', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Extracted Data View', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 6),
        Text('Review digitized information for accuracy.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        _DataRow(label: 'Medication', value: 'Amoxicillin 500mg'),
        const SizedBox(height: 8),
        _DataRow(label: 'Dosage', value: '1 capsule, 3 times a day'),
        const SizedBox(height: 8),
        _DataRow(label: 'Prescriber', value: 'Dr. Elizabeth Marsh'),
        const SizedBox(height: 8),
        _DataRow(label: 'Facility', value: 'City Health Hospital'),
      ],
    );
  }

  Widget _buildFinalizeButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Finalize Passport Entry',
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Confirm the extracted data and upload to your medical identity.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Save to Health Passport'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check, color: AppColors.primary, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4)),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}
