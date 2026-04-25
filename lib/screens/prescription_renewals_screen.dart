import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class PrescriptionRenewalsScreen extends ConsumerWidget {
  const PrescriptionRenewalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);

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
        padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 16, Responsive.hPad(context), 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescription\nRenewals',
                style: GoogleFonts.manrope(fontSize: Responsive.fontSize(context, 26), fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.15)),
            const SizedBox(height: 8),
            Text('Manage your active medications and set up automated refills to stay on track with your health.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 24),
            _buildRenewalHub(),
            const SizedBox(height: 24),
            Text('Current Medications', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 16),
            prescriptionsAsync.when(
              data: (prescriptions) {
                final active = prescriptions.where((rx) => rx.status == PrescriptionStatus.active).toList();
                if (active.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No active prescriptions', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                    ),
                  );
                }
                return Column(
                  children: active.expand((rx) {
                    return (rx.items ?? []).map((item) {
                      final totalDays = item.durationDays ?? 180;
                      final remaining = item.remaining ?? item.quantity ?? totalDays;
                      final total = item.quantity ?? totalDays;
                      final progress = total > 0 ? remaining / total : 0.0;
                      final daysLeft = remaining;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MedicationCard(
                          name: item.medicationName,
                          dosage: '${item.dosage} • ${item.frequency}',
                          nextRefill: '$daysLeft left',
                          progress: progress.clamp(0.0, 1.0),
                          status: rx.status == PrescriptionStatus.active ? 'Active' : '',
                          isAutomated: true,
                          onRequestRenewal: () {
                            ref.read(prescriptionRepositoryProvider).requestRenewal(rx.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Renewal requested')),
                            );
                          },
                        ),
                      );
                    });
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
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
  final VoidCallback? onRequestRenewal;

  const _MedicationCard({
    required this.name,
    required this.dosage,
    required this.nextRefill,
    required this.progress,
    required this.status,
    required this.isAutomated,
    this.onRequestRenewal,
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
                  Flexible(
                    child: Text(nextRefill, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ),
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
                onPressed: onRequestRenewal,
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
