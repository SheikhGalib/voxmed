import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class CollaborativeHubScreen extends StatelessWidget {
  const CollaborativeHubScreen({super.key});

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientCard(),
            const SizedBox(height: 16),
            _buildVitalsRow(),
            const SizedBox(height: 20),
            _buildCollaborativeExchange(),
            const SizedBox(height: 20),
            _buildClinicalHistory(),
            const SizedBox(height: 20),
            _buildAssignedSpecialists(),
            const SizedBox(height: 20),
            _buildTreatmentThread(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return VoxmedCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondaryContainer,
                child: const Icon(Icons.person, size: 28, color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eleanor Vance',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                    Text('Patient ID: 864184350',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Badge(label: 'GENERATE REPORT', color: AppColors.primary, bgColor: AppColors.primaryContainer.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              _Badge(label: 'START PROMPTS', color: AppColors.onSurfaceVariant, bgColor: AppColors.surfaceContainerLow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REAL-TIME VITALS',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _VitalChip(label: 'HR', value: '72', unit: 'bpm')),
              const SizedBox(width: 8),
              Expanded(child: _VitalChip(label: 'BP', value: '118/74', unit: '')),
              const SizedBox(width: 8),
              Expanded(child: _VitalChip(label: 'SpO₂', value: '98.6', unit: '%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeExchange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Collaborative Exchange',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Securely share records via FHIR-based API with external specialists for peer review and collaborative analysis.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.security, size: 16),
            label: Text('Secure File Share', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Text('Clinical History',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type 2 Diabetes Mellitus',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text('Prescriber: LJones',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedSpecialists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group, color: AppColors.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Text('Labs',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HbA1c', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  Text('Latest reading', style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
              Text('0.9 mg/L', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentThread() {
    return VoxmedCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.2),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Treatment Collaboration Thread',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on the latest lab results, we should consider adjusting the medication protocol. The HbA1c results are trending in a positive direction, though we should monitor the patient closely.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark_border, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('Send baseline to endocrinologist',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: color)),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalChip({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(unit, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
