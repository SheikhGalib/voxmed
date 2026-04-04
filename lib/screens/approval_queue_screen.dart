import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renewalsAsync = ref.watch(pendingRenewalsProvider);

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
            _buildQueueStats(renewalsAsync),
            const SizedBox(height: 24),
            _buildRenewalsList(context, ref, renewalsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStats(AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    final count = renewalsAsync.valueOrNull?.length ?? 0;

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
                Text('$count', style: GoogleFonts.manrope(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pending_actions, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('pending', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                    Text('—', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
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
                    Text('STATUS',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(count > 0 ? 'Active' : 'Clear', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRenewalsList(BuildContext context, WidgetRef ref, AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    return renewalsAsync.when(
      data: (renewals) {
        if (renewals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('All caught up!', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                  Text('No pending renewal requests.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: renewals.map((r) {
            final patientName = r['profiles']?['full_name'] ?? 'Unknown';
            final items = r['prescriptions']?['prescription_items'] as List? ?? [];
            final medication = items.isNotEmpty ? '${items.first['medication_name']} ${items.first['dosage'] ?? ''}' : 'Medication';
            final reason = r['reason'] ?? 'Renewal request';
            final renewalId = r['id'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildApprovalCard(
                context: context,
                ref: ref,
                renewalId: renewalId,
                name: patientName,
                status: 'Pending',
                statusColor: AppColors.secondary,
                medication: medication,
                reason: reason,
                avatar: Icons.person,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (_, __) => Center(child: Text('Failed to load renewals', style: GoogleFonts.inter(color: AppColors.error))),
    );
  }

  Widget _buildApprovalCard({
    required BuildContext context,
    required WidgetRef ref,
    required String renewalId,
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
                  onPressed: () => _handleAction(context, ref, renewalId, 'rejected'),
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
                  onPressed: () => _handleAction(context, ref, renewalId, 'approved'),
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

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String renewalId, String status) async {
    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      final renewalStatus = status == 'approved' ? RenewalStatus.approved : RenewalStatus.rejected;
      await repo.updateRenewalStatus(renewalId, renewalStatus);
      ref.invalidate(pendingRenewalsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renewal ${status == 'approved' ? 'approved' : 'denied'} successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
