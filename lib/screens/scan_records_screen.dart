import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class ScanRecordsScreen extends StatelessWidget {
  const ScanRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.medical_information_outlined, color: AppColors.primary, size: 24),
          ],
        ),
        title: Text('VoxMed', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
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
            const SizedBox(height: 24),
            _buildExtractedData(),
            const SizedBox(height: 24),
            _buildFinalizeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanArea() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner corners
          ...List.generate(4, (i) {
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
              Text('Auto-capture enabled',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOCRTips() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
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
