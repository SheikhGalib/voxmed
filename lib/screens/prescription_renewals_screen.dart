import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class PrescriptionRenewalsScreen extends StatelessWidget {
  const PrescriptionRenewalsScreen({super.key});

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
            Text('Prescription\nRenewals',
                style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.15)),
            const SizedBox(height: 8),
            Text('Manage your active medications and set up automated refills to stay on track with your health.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 24),
            _buildRenewalHub(),
            const SizedBox(height: 24),
            Text('Current Medications', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 16),
            _MedicationCard(
              name: 'Lisinopril',
              dosage: '10mg • 1x daily',
              nextRefill: 'Oct 12',
              progress: 0.65,
              status: 'Active',
              isAutomated: true,
            ),
            const SizedBox(height: 12),
            _MedicationCard(
              name: 'Metformin',
              dosage: '500mg • 2x daily',
              nextRefill: 'Nov 04',
              progress: 0.85,
              status: '23 Days',
              isAutomated: false,
            ),
            const SizedBox(height: 12),
            _MedicationCard(
              name: 'Atorvastatin',
              dosage: '20mg • 1x nightly',
              nextRefill: 'Nov 28',
              progress: 0.92,
              status: '',
              isAutomated: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalHub() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, size: 12, color: AppColors.onTertiaryContainer),
                    const SizedBox(width: 4),
                    Text('SMARTFHIR ACTIVE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onTertiaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.autorenew, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Automated Renewal Hub',
                        style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Text('VoxMed AI monitors your supply and requests renewals from your physician 5 days before you run out.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('View Renewal History', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String nextRefill;
  final double progress;
  final String status;
  final bool isAutomated;

  const _MedicationCard({
    required this.name,
    required this.dosage,
    required this.nextRefill,
    required this.progress,
    required this.status,
    required this.isAutomated,
  });

  @override
  Widget build(BuildContext context) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(dosage, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
              if (isAutomated)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.autorenew, color: AppColors.primary, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? AppColors.primary : progress > 0.5 ? AppColors.tertiary : AppColors.error),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(nextRefill, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                ],
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onTertiaryContainer)),
                ),
            ],
          ),
          if (!isAutomated) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Request Automated Renewal', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
