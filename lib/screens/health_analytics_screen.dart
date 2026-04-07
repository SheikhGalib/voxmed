import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class HealthAnalyticsScreen extends ConsumerWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherenceAsync = ref.watch(adherenceStatsProvider);
    final wearableAsync = ref.watch(wearableDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Insights',
              style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text('Real-time analysis of your physiological data and treatment compliance.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 24),
          _buildMedicationAdherence(adherenceAsync),
          const SizedBox(height: 16),
          _buildOuraRingCard(wearableAsync),
          const SizedBox(height: 16),
          _buildBloodPressureTrends(wearableAsync),
          const SizedBox(height: 16),
          _buildVitalsIntegrity(adherenceAsync),
          const SizedBox(height: 16),
          _buildHeartRateSummary(wearableAsync),
        ],
      ),
    );
  }

  Widget _buildMedicationAdherence(AsyncValue<Map<String, dynamic>> adherenceAsync) {
    final rate = adherenceAsync.when(
      data: (stats) => (stats['rate'] as int?) ?? 0,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return VoxmedCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medication Adherence',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text('Last 30-Day Compliance',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: rate / 100.0,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('$rate%',
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOuraRingCard(AsyncValue<Map<String, dynamic>> wearableAsync) {
    final sleepScore = wearableAsync.when(
      data: (data) {
        final sleepList = data['sleep'] as List? ?? [];
        if (sleepList.isEmpty) return 0;
        final val = sleepList.first['value'];
        if (val is Map) return val['score'] ?? 0;
        return 0;
      },
      loading: () => 0,
      error: (_, _) => 0,
    );

    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.watch, color: AppColors.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Oura Ring',
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sleepScore',
                  style: GoogleFonts.manrope(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('/100',
                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Readiness Score',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sleepScore / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureTrends(AsyncValue<Map<String, dynamic>> wearableAsync) {
    String systolic = '--';
    String diastolic = '--';
    String pulse = '--';

    wearableAsync.whenData((data) {
      final bpList = data['blood_pressure'] as List? ?? [];
      if (bpList.isNotEmpty) {
        final latest = bpList.first['value'];
        if (latest is Map) {
          systolic = '${latest['systolic'] ?? '--'}';
          diastolic = '${latest['diastolic'] ?? '--'}';
        }
      }
      final hrList = data['heart_rate'] as List? ?? [];
      if (hrList.isNotEmpty) {
        final latest = hrList.first['value'];
        if (latest is Map) pulse = '${latest['bpm'] ?? '--'}';
      }
    });

    return VoxmedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Blood Pressure Trends',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text('Systolic and Diastolic comparison',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _BPChartPainter(),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BPReading(label: 'SYSTOLIC', value: systolic, unit: 'mmHg', color: AppColors.primary),
              Container(height: 40, width: 1, color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _BPReading(label: 'DIASTOLIC', value: diastolic, unit: 'mmHg', color: AppColors.secondary),
              Container(height: 40, width: 1, color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _BPReading(label: 'PULSE', value: pulse, unit: 'bpm', color: AppColors.tertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsIntegrity(AsyncValue<Map<String, dynamic>> adherenceAsync) {
    final rate = adherenceAsync.when(
      data: (stats) => (stats['rate'] as int?) ?? 0,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final grade = rate >= 90 ? 'A+' : rate >= 80 ? 'A' : rate >= 70 ? 'B+' : rate >= 60 ? 'B' : 'C';

    return VoxmedCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(grade,
                  style: GoogleFonts.manrope(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vitals Integrity',
                        style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Text('Your comprehensive score is in the\ntop 5% for your age group.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateSummary(AsyncValue<Map<String, dynamic>> wearableAsync) {
    final restingHr = wearableAsync.when(
      data: (data) {
        final hrList = data['heart_rate'] as List? ?? [];
        if (hrList.isEmpty) return '--';
        // Find lowest (resting) heart rate
        int minBpm = 999;
        for (final hr in hrList) {
          final val = hr['value'];
          if (val is Map) {
            final bpm = val['bpm'] as int? ?? 999;
            if (bpm < minBpm) minBpm = bpm;
          }
        }
        return minBpm == 999 ? '--' : '$minBpm';
      },
      loading: () => '...',
      error: (_, _) => '--',
    );

    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.favorite, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resting Heart Rate',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(restingHr,
                      style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.1)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('BPM',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BPReading extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _BPReading({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(unit, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _BPChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final systolicPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final diastolicPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final systolicPath = Path();
    final diastolicPath = Path();

    final systolicPoints = [0.4, 0.35, 0.45, 0.3, 0.38, 0.32, 0.4, 0.35];
    final diastolicPoints = [0.7, 0.65, 0.72, 0.6, 0.68, 0.63, 0.7, 0.65];

    for (int i = 0; i < systolicPoints.length; i++) {
      final x = i * size.width / (systolicPoints.length - 1);
      final sy = systolicPoints[i] * size.height;
      final dy = diastolicPoints[i] * size.height;

      if (i == 0) {
        systolicPath.moveTo(x, sy);
        diastolicPath.moveTo(x, dy);
      } else {
        final px = (i - 1) * size.width / (systolicPoints.length - 1);
        final psy = systolicPoints[i - 1] * size.height;
        final pdy = diastolicPoints[i - 1] * size.height;
        final cx = (px + x) / 2;

        systolicPath.cubicTo(cx, psy, cx, sy, x, sy);
        diastolicPath.cubicTo(cx, pdy, cx, dy, x, dy);
      }
    }

    canvas.drawPath(systolicPath, systolicPaint);
    canvas.drawPath(diastolicPath, diastolicPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
