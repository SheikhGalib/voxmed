import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/medical_record.dart';
import '../providers/medical_record_provider.dart';

/// Full-screen view of a single medical record.
///
/// Shows all OCR-extracted fields, raw text (scrollable), and record metadata.
/// Accessible from both the patient's Health Passport and the doctor's
/// Patient Detail screen.
class RecordDetailScreen extends ConsumerWidget {
  final String recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(medicalRecordDetailProvider(recordId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Text(
          'Record Details',
          style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface),
        ),
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load record: $e',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (record) => _RecordDetailBody(record: record),
      ),
    );
  }
}

class _RecordDetailBody extends StatelessWidget {
  final MedicalRecord record;

  const _RecordDetailBody({required this.record});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(record: record),
          const SizedBox(height: 16),
          if (record.description != null && record.description!.isNotEmpty) ...[
            _SectionTitle('Description'),
            const SizedBox(height: 8),
            _InfoCard(
              child: Text(
                record.description!,
                style: GoogleFonts.inter(
                    fontSize: 14, height: 1.6, color: AppColors.onSurface),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (record.ocrExtracted) ...[
            _OcrDataSection(record: record),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────── HEADER CARD ────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final MedicalRecord record;

  const _HeaderCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(record.recordType);
    final dateStr = record.recordDate != null
        ? DateFormat('d MMMM yyyy').format(record.recordDate!)
        : DateFormat('d MMMM yyyy').format(record.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              record.isPdf ? Icons.picture_as_pdf : Icons.description_outlined,
              color: typeColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(record.recordType.value, typeColor),
                    if (record.ocrExtracted)
                      _Chip(
                        record.ocrEngine?.label ?? 'OCR',
                        AppColors.primary,
                        icon: Icons.auto_awesome,
                      ),
                    if (record.isPdf) _Chip('PDF', AppColors.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForType(RecordType type) {
    switch (type) {
      case RecordType.prescription:
        return const Color(0xFF0D6EFD);
      case RecordType.labResult:
        return const Color(0xFF198754);
      case RecordType.radiology:
        return const Color(0xFFE0962A);
      case RecordType.dischargeSummary:
        return const Color(0xFF6F42C1);
      case RecordType.consultationNote:
        return const Color(0xFF0DCAF0);
      case RecordType.other:
        return AppColors.onSurfaceVariant;
    }
  }
}

// ──────────────────────────────── OCR SECTION ────────────────────────────────

class _OcrDataSection extends StatelessWidget {
  final MedicalRecord record;

  const _OcrDataSection({required this.record});

  @override
  Widget build(BuildContext context) {
    final data = record.data ?? {};

    // Structured fields (excluding internal keys)
    const _internalKeys = {
      'local_file_path',
      'file_type',
      'ocr_engine',
      'raw_text',
    };

    final structuredFields = <String, String>{};
    for (final entry in data.entries) {
      if (_internalKeys.contains(entry.key)) continue;
      final v = entry.value;
      if (v == null || v.toString().isEmpty || v.toString() == 'null') continue;
      structuredFields[entry.key] = v.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (structuredFields.isNotEmpty) ...[
          _SectionTitle('Extracted Information'),
          const SizedBox(height: 8),
          _InfoCard(
            child: Column(
              children: structuredFields.entries
                  .map((e) => _FieldRow(
                        label: _labelFor(e.key),
                        value: e.value,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (record.ocrRawText != null && record.ocrRawText!.isNotEmpty) ...[
          _SectionTitle('Full Text'),
          const SizedBox(height: 8),
          _RawTextCard(text: record.ocrRawText!),
        ],
      ],
    );
  }

  String _labelFor(String key) {
    const labels = {
      'medication_name': 'Medication',
      'dosage': 'Dosage',
      'doctor_name': 'Doctor',
      'patient_name': 'Patient',
      'date': 'Date',
      'diagnosis': 'Diagnosis',
      'instructions': 'Instructions',
      'hospital_name': 'Hospital',
    };
    return labels[key] ??
        key
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }
}

// ──────────────────────────────── SMALL WIDGETS ──────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurface, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RawTextCard extends StatefulWidget {
  final String text;

  const _RawTextCard({required this.text});

  @override
  State<_RawTextCard> createState() => _RawTextCardState();
}

class _RawTextCardState extends State<_RawTextCard> {
  bool _expanded = false;

  static const int _collapseThreshold = 400;

  bool get _needsCollapse => widget.text.length > _collapseThreshold;

  @override
  Widget build(BuildContext context) {
    final displayText = _needsCollapse && !_expanded
        ? '${widget.text.substring(0, _collapseThreshold)}…'
        : widget.text;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              displayText,
              style: GoogleFonts.jetBrainsMono != null
                  ? GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.onSurface,
                      fontFeatures: null)
                  : GoogleFonts.inter(
                      fontSize: 13, height: 1.6, color: AppColors.onSurface),
            ),
          ),
          if (_needsCollapse)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Show less' : 'Show full text',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Chip(this.label, this.color, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color),
          ),
        ],
      ),
    );
  }
}
