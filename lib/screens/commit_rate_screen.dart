import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../models/medication_schedule.dart';
import '../providers/medication_schedule_provider.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class CommitRateScreen extends ConsumerWidget {
  const CommitRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adherenceStatsProvider);
    final detailsAsync = ref.watch(adherenceDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Commit Rate',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adherenceStatsProvider);
              ref.invalidate(adherenceTrendProvider);
              ref.invalidate(adherenceDetailsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Responsive.hPad(context),
          16,
          Responsive.hPad(context),
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(statsAsync),
            const SizedBox(height: 16),
            _buildTotals(detailsAsync),
            const SizedBox(height: 16),
            _buildIntakeList(context, detailsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AsyncValue<Map<String, dynamic>> statsAsync) {
    final stats = statsAsync.valueOrNull ?? const <String, dynamic>{};
    final rate = stats['rate'] as int? ?? 0;
    final taken = stats['taken'] as int? ?? 0;
    final missed = stats['missed'] as int? ?? 0;
    final skipped = stats['skipped'] as int? ?? 0;
    final total = stats['total'] as int? ?? 0;
    final gradeColor = _rateColor(rate);

    return VoxmedCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30-Day Commitment',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$taken taken | $missed missed | $skipped skipped',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$total logged doses',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$rate%',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(AsyncValue<List<MedicationAdherenceEntry>> detailsAsync) {
    final entries =
        detailsAsync.valueOrNull ?? const <MedicationAdherenceEntry>[];
    final taken = entries
        .where((e) => e.status == AdherenceStatus.taken)
        .length;
    final missed = entries
        .where((e) => e.status == AdherenceStatus.missed)
        .length;
    final skipped = entries
        .where((e) => e.status == AdherenceStatus.skipped)
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatusTotal(
            label: 'Taken',
            value: taken,
            color: AppColors.primary,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusTotal(
            label: 'Missed',
            value: missed,
            color: AppColors.error,
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusTotal(
            label: 'Skipped',
            value: skipped,
            color: Colors.orange.shade700,
            icon: Icons.remove_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildIntakeList(
    BuildContext context,
    AsyncValue<List<MedicationAdherenceEntry>> detailsAsync,
  ) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Intake',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 30 days',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          detailsAsync.when(
            loading: () => const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _EmptyIntakeState(
              onSchedule: () => context.push(AppRoutes.medicationSchedule),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return _EmptyIntakeState(
                  onSchedule: () => context.push(AppRoutes.medicationSchedule),
                );
              }

              return Column(
                children: entries.take(60).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IntakeRow(entry: entry),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 90) return AppColors.primary;
    if (rate >= 70) return Colors.green.shade600;
    if (rate >= 50) return Colors.orange.shade700;
    return AppColors.error;
  }
}

class _StatusTotal extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatusTotal({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  final MedicationAdherenceEntry entry;

  const _IntakeRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(entry.status);
    final date = DateFormat('MMM d, h:mm a').format(entry.scheduledTime);
    final subtitle = [
      if (entry.dosage != null && entry.dosage!.isNotEmpty) entry.dosage!,
      date,
    ].join(' | ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(entry.status), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.medicationName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              entry.statusLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return AppColors.primary;
      case AdherenceStatus.missed:
        return AppColors.error;
      case AdherenceStatus.skipped:
        return Colors.orange.shade700;
      case AdherenceStatus.pending:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _statusIcon(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return Icons.check_circle;
      case AdherenceStatus.missed:
        return Icons.cancel_outlined;
      case AdherenceStatus.skipped:
        return Icons.remove_circle_outline;
      case AdherenceStatus.pending:
        return Icons.schedule;
    }
  }
}

class _EmptyIntakeState extends StatelessWidget {
  final VoidCallback onSchedule;

  const _EmptyIntakeState({required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.medication_outlined,
            color: AppColors.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'No intake logs yet',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onSchedule,
            icon: const Icon(Icons.alarm_add, size: 18),
            label: Text(
              'Schedule Medicine',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
