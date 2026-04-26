import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../providers/medication_schedule_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/medical_record_provider.dart';
import '../widgets/voxmed_card.dart';

class HealthAnalyticsScreen extends ConsumerWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherenceAsync = ref.watch(adherenceStatsProvider);
    final trendAsync = ref.watch(adherenceTrendProvider);
    final upcomingAsync = ref.watch(upcomingDosesProvider);
    final recordsAsync = ref.watch(recentMedicalRecordsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Responsive.hPad(context),
        16,
        Responsive.hPad(context),
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Insights',
            style: GoogleFonts.manrope(
              fontSize: Responsive.fontSize(context, 26),
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your medication commitment and health record trends.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildCommitRate(context, adherenceAsync),
          const SizedBox(height: 16),
          _buildIntakeTrendChart(trendAsync),
          const SizedBox(height: 16),
          _buildUpcomingScheduleCard(context, upcomingAsync),
          const SizedBox(height: 16),
          _buildReportTrends(recordsAsync),
        ],
      ),
    );
  }

  // ── Commit Rate ──────────────────────────────────────────────────────────

  Widget _buildCommitRate(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> adherenceAsync,
  ) {
    final rate = adherenceAsync.when(
      data: (stats) => (stats['rate'] as int?) ?? 0,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final grade = rate >= 90
        ? 'Excellent'
        : rate >= 70
        ? 'Good'
        : rate >= 50
        ? 'Fair'
        : 'Needs Attention';
    final gradeColor = rate >= 90
        ? AppColors.primary
        : rate >= 70
        ? Colors.green.shade600
        : rate >= 50
        ? Colors.orange.shade600
        : AppColors.error;

    return VoxmedCard(
      onTap: () => context.push(AppRoutes.commitRate),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Commit Rate',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '30-Day medication adherence',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    grade,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: rate / 100.0,
                  strokeWidth: 7,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$rate%',
                style: GoogleFonts.manrope(
                  fontSize: 18,
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

  // ── 30-Day Intake Trend ───────────────────────────────────────────────────

  Widget _buildIntakeTrendChart(
    AsyncValue<List<Map<String, dynamic>>> trendAsync,
  ) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30-Day Intake Trend',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily doses taken vs. missed',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox(height: 80),
            data: (trend) {
              if (trend.isEmpty) {
                return SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'No data yet. Start scheduling your medicines.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              // Show last 14 days max for readability
              final data = trend.length > 14
                  ? trend.sublist(trend.length - 14)
                  : trend;
              final maxVal = data.fold<int>(1, (m, e) {
                final t =
                    (e['taken'] as int? ?? 0) + (e['missed'] as int? ?? 0);
                return t > m ? t : m;
              });

              return SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((day) {
                    final taken = (day['taken'] as int? ?? 0);
                    final missed = (day['missed'] as int? ?? 0);
                    final total = (taken + missed).clamp(1, 999);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _StackedBar(
                              taken: taken,
                              missed: missed,
                              total: total,
                              maxVal: maxVal,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: AppColors.primary, label: 'Taken'),
              const SizedBox(width: 16),
              _Legend(
                color: AppColors.error.withValues(alpha: 0.7),
                label: 'Missed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Upcoming Schedule ─────────────────────────────────────────────────────

  Widget _buildUpcomingScheduleCard(
    BuildContext context,
    AsyncValue<List<Map<String, String>>> upcomingAsync,
  ) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.medicationSchedule),
      child: VoxmedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Doses',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.alarm,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
            upcomingAsync.when(
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox(height: 60),
              data: (doses) {
                if (doses.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No upcoming doses for today.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: doses.take(3).map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              d['medication_name'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            d['time'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Trends ─────────────────────────────────────────────────────────

  Widget _buildReportTrends(AsyncValue records) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Trends',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Health records uploaded by type',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          records.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox(height: 60),
            data: (recs) {
              if (recs.isEmpty) {
                return Text(
                  'No reports uploaded yet.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              }

              // Count by type using the stable .value getter
              final counts = <String, int>{};
              for (final r in recs) {
                final type = r.recordType.value;
                counts[type] = (counts[type] ?? 0) + 1;
              }

              return Column(
                children: counts.entries.map((e) {
                  final total = recs.length;
                  final pct = (e.value / total);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _typeLabel(e.key),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _typeLabel(String key) {
    const labels = {
      'prescription': 'Prescription',
      'lab_result': 'Lab Result',
      'radiology': 'Radiology',
      'discharge_summary': 'Discharge Summary',
      'consultation_note': 'Consultation Note',
      'other': 'Other',
    };
    return labels[key] ?? key;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StackedBar extends StatelessWidget {
  final int taken;
  final int missed;
  final int total;
  final int maxVal;

  const _StackedBar({
    required this.taken,
    required this.missed,
    required this.total,
    required this.maxVal,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = 90.0;
    final takenH = (taken / maxVal) * barHeight;
    final missedH = (missed / maxVal) * barHeight;

    return SizedBox(
      height: barHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (missedH > 0)
            Container(
              height: missedH,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (takenH > 0)
            Container(
              height: takenH,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
