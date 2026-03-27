import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

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
            Text('Approvals',
                style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text('Review and authorize renewal requests from patients in your care.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 24),
            _buildQueueStats(),
            const SizedBox(height: 24),
            _buildApprovalCard(
              name: 'Matt Park',
              status: 'Priority',
              statusColor: AppColors.error,
              medication: 'Lisinopril 10mg',
              reason: 'Routine Renewal',
              avatar: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildApprovalCard(
              name: 'Marcus Thorne',
              status: 'Routine',
              statusColor: AppColors.secondary,
              medication: 'Lisinopril 10mg',
              reason: 'Routine Renewal',
              avatar: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildApprovalCard(
              name: 'Elena Rodriguez',
              status: 'Follow-up',
              statusColor: AppColors.tertiary,
              medication: 'Berberine 50mg',
              reason: 'Dosage adjustment',
              avatar: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildApprovalCard(
              name: 'Samuel Wu',
              status: 'New',
              statusColor: AppColors.primary,
              medication: 'Metformin 500mg',
              reason: 'New prescription',
              avatar: Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStats() {
    return Row(
      children: [
        Expanded(
          child: VoxmedCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIORITY QUEUE',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('12', style: GoogleFonts.manrope(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('+3 today', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              VoxmedCard(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APPROVAL RATE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('88%', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VoxmedCard(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMPLIANCE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Ha', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard({
    required String name,
    required String status,
    required Color statusColor,
    required String medication,
    required String reason,
    required IconData avatar,
  }) {
    return VoxmedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(avatar, color: AppColors.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(medication, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Text('Deny', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('Approve', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
