import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class ClinicalDashboardScreen extends ConsumerWidget {
  const ClinicalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(doctorStatsProvider);
    final scheduleAsync = ref.watch(doctorTodayAppointmentsProvider);
    final renewalsAsync = ref.watch(pendingRenewalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2332),
        leading: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.medical_information_outlined, color: Colors.white, size: 24),
          ],
        ),
        title: Text('VoxMed', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('Emergency Attention', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDarkStatsBar(statsAsync, scheduleAsync),
            const SizedBox(height: 20),
            _buildDailySchedule(scheduleAsync),
            const SizedBox(height: 20),
            _buildComplianceTrends(statsAsync),
            const SizedBox(height: 20),
            _buildApprovalsRequired(renewalsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkStatsBar(AsyncValue<Map<String, dynamic>> statsAsync, AsyncValue<List<Map<String, dynamic>>> scheduleAsync) {
    final stats = statsAsync.valueOrNull ?? {};
    final schedule = scheduleAsync.valueOrNull ?? [];
    final patientsCount = stats['patients_count'] ?? 0;
    final pendingRenewals = stats['pending_renewals'] ?? 0;
    final pendingLabs = stats['pending_labs'] ?? 0;
    final complianceRate = pendingRenewals == 0 ? 100 : (patientsCount > 0 ? ((patientsCount - pendingRenewals) / patientsCount * 100).round() : 0);
    final nextPatient = schedule.isNotEmpty ? schedule.first : null;
    final nextName = nextPatient != null ? (nextPatient['profiles']?['full_name'] ?? 'Unknown') : '—';
    final nextReason = nextPatient != null ? (nextPatient['reason'] ?? nextPatient['type'] ?? '') : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(label: 'ACTIVE PATIENTS', value: '$patientsCount', color: Colors.cyanAccent)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'COMPLIANCE', value: '$complianceRate%', color: Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'PENDING LAB REVIEW', value: pendingLabs.toString().padLeft(2, '0'), color: Colors.orangeAccent)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: Colors.white70, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nextName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                            Text(nextReason, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySchedule(AsyncValue<List<Map<String, dynamic>>> scheduleAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Schedule', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 14),
        scheduleAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('No appointments today', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant))),
              );
            }
            return Column(
              children: appointments.map((apt) {
                final start = DateTime.tryParse(apt['scheduled_start_at'] ?? '');
                final end = DateTime.tryParse(apt['scheduled_end_at'] ?? '');
                final time = start != null ? DateFormat('hh:mm').format(start.toLocal()) : '--:--';
                final name = apt['profiles']?['full_name'] ?? 'Unknown';
                final reason = apt['reason'] ?? apt['type'] ?? 'Consultation';
                final durationMin = (start != null && end != null) ? end.difference(start).inMinutes : 30;
                return _ScheduleItem(time: time, name: name, type: reason, duration: '$durationMin min');
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text('Failed to load schedule', style: GoogleFonts.inter(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildComplianceTrends(AsyncValue<Map<String, dynamic>> statsAsync) {
    final stats = statsAsync.valueOrNull ?? {};
    final rating = (stats['rating'] ?? 0.0) as num;
    final ratingPct = (rating / 5.0).clamp(0.0, 1.0).toDouble();
    String grade;
    if (rating >= 4.5) {
      grade = 'A+';
    } else if (rating >= 4.0) {
      grade = 'A';
    } else if (rating >= 3.5) {
      grade = 'B+';
    } else if (rating >= 3.0) {
      grade = 'B';
    } else {
      grade = 'C';
    }

    return VoxmedCard(
      child: Column(
        children: [
          Text('Patient Compliance Trends', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: ratingPct,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(grade, style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Average', style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('RATING: ${rating.toStringAsFixed(1)} / 5.0', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratingPct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsRequired(AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Approvals Required', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 14),
        renewalsAsync.when(
          data: (renewals) {
            if (renewals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('No pending approvals', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant))),
              );
            }
            return Column(
              children: renewals.take(3).map((r) {
                final patientName = r['profiles']?['full_name'] ?? 'Unknown';
                final items = r['prescriptions']?['prescription_items'] as List? ?? [];
                final drug = items.isNotEmpty ? items.first['medication_name'] ?? 'Medication' : 'Medication';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ApprovalItem(name: patientName, drug: drug, hasAction: true),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text('Failed to load approvals', style: GoogleFonts.inter(color: AppColors.error)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String name;
  final String type;
  final String duration;

  const _ScheduleItem({required this.time, required this.name, required this.type, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(time, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
          ),
          Container(
            width: 2,
            height: 56,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    child: const Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        Text(type, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(duration, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  final String name;
  final String drug;
  final bool hasAction;

  const _ApprovalItem({required this.name, required this.drug, this.hasAction = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceContainerHighest,
            child: const Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                Text(drug, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (hasAction)
            Row(
              children: [
                Text('Review \$98+/visit', style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
