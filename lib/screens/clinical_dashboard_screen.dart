import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/prescription_provider.dart';
import '../providers/doctor_provider.dart';

class ClinicalDashboardScreen extends ConsumerWidget {
  const ClinicalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDoctorAsync = ref.watch(currentDoctorProvider);

    final doctor = currentDoctorAsync.valueOrNull;
    if (doctor != null && doctor.status != DoctorStatus.approved) {
      return _buildPendingApprovalScreen(doctor.status);
    }

    final statsAsync = ref.watch(doctorStatsProvider);
    final scheduleAsync = ref.watch(doctorTodayAppointmentsProvider);
    final renewalsAsync = ref.watch(pendingRenewalsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 16, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(context, statsAsync),
          const SizedBox(height: 24),
          _buildScheduleSection(context, scheduleAsync),
          const SizedBox(height: 24),
          _buildApprovalsSection(context, ref, renewalsAsync),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalScreen(String status) {
    final isRejected = status == DoctorStatus.rejected;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isRejected
                    ? AppColors.errorContainer.withValues(alpha: 0.15)
                    : DoctorColors.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top_outlined,
                size: 56,
                color: isRejected ? AppColors.error : DoctorColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isRejected ? 'Profile Not Approved' : 'Approval Pending',
              style: GoogleFonts.manrope(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              isRejected
                  ? 'Your profile was not approved by the hospital. Please contact the hospital administration.'
                  : 'Your profile is under review. You will gain full access after approval.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppColors.onSurfaceVariant, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ─── White stats cards with blue border ───────────────────────────────────

  Widget _buildStatsRow(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    final stats = statsAsync.valueOrNull ?? {};
    final patientsCount = stats['patients_count'] ?? 0;
    final pendingRenewals = stats['pending_renewals'] ?? 0;
    final pendingLabs = stats['pending_labs'] ?? 0;
    final complianceRate = pendingRenewals == 0
        ? 100
        : (patientsCount > 0
            ? ((patientsCount - pendingRenewals) / patientsCount * 100).round()
            : 0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'ACTIVE PATIENTS',
              value: '$patientsCount',
              icon: Icons.people_alt_outlined,
              color: DoctorColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'COMPLIANCE',
              value: '$complianceRate%',
              icon: Icons.check_circle_outline,
              color: DoctorColors.statGreen,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'PENDING LABS',
              value: pendingLabs.toString().padLeft(2, '0'),
              icon: Icons.science_outlined,
              color: DoctorColors.statOrange,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'RENEWALS',
              value: pendingRenewals.toString().padLeft(2, '0'),
              icon: Icons.assignment_outlined,
              color: DoctorColors.accentLight,
            )),
          ],
        ),
      ],
    );
  }

  // ─── Schedule section ──────────────────────────────────────────────────────

  Widget _buildScheduleSection(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> scheduleAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Today's Schedule",
                style: GoogleFonts.manrope(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.doctorSchedule),
              icon: const Icon(Icons.calendar_month, size: 16, color: DoctorColors.primary),
              label: Text('Full view',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: DoctorColors.primary)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        scheduleAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DoctorColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DoctorColors.border, width: 1),
                ),
                child: Center(
                  child: Text('No appointments scheduled for today',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                ),
              );
            }
            return Column(
              children: appointments.take(5).map((apt) {
                final start = DateTime.tryParse(apt['scheduled_start_at'] ?? '');
                final end = DateTime.tryParse(apt['scheduled_end_at'] ?? '');
                final time = start != null ? DateFormat('hh:mm a').format(start.toLocal()) : '--:--';
                final name = apt['profiles']?['full_name'] ?? 'Unknown';
                final reason = apt['reason'] ?? apt['type'] ?? 'Consultation';
                final durationMin =
                    (start != null && end != null) ? end.difference(start).inMinutes : 30;
                return _ScheduleItem(
                    time: time, name: name, type: reason, duration: '$durationMin min');
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              Text('Failed to load schedule', style: GoogleFonts.inter(color: AppColors.error)),
        ),
      ],
    );
  }

  // ─── Approvals section ─────────────────────────────────────────────────────

  Widget _buildApprovalsSection(
      BuildContext context, WidgetRef ref, AsyncValue<List<Map<String, dynamic>>> renewalsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Approval Requests',
                style: GoogleFonts.manrope(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.approvalQueue),
              icon: const Icon(Icons.open_in_new, size: 14, color: DoctorColors.primary),
              label: Text('See all',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: DoctorColors.primary)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        renewalsAsync.when(
          data: (renewals) {
            if (renewals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DoctorColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DoctorColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: DoctorColors.statGreen, size: 22),
                    const SizedBox(width: 12),
                    Text('All caught up! No pending approvals.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return Column(
              children: renewals.take(3).map((r) {
                final patientName = r['profiles']?['full_name'] ?? 'Unknown';
                final items = r['prescriptions']?['prescription_items'] as List? ?? [];
                final drug = items.isNotEmpty
                    ? (items.first['medication_name'] ?? 'Medication')
                    : 'Medication';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DashboardApprovalTile(
                    name: patientName,
                    drug: drug,
                    onTap: () => context.go(AppRoutes.approvalQueue),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text('Failed to load approvals',
              style: GoogleFonts.inter(color: AppColors.error)),
        ),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DoctorColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: Responsive.fontSize(context, 26),
                  fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─── Schedule item row ────────────────────────────────────────────────────────

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String name;
  final String type;
  final String duration;

  const _ScheduleItem(
      {required this.time, required this.name, required this.type, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(time,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
          ),
          Container(
            width: 2,
            height: 56,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: DoctorColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DoctorColors.border, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: DoctorColors.primaryContainer,
                    child: const Icon(Icons.person, size: 18, color: DoctorColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        Text(type,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(duration,
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600, color: DoctorColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Approval tile (dashboard quick view) ────────────────────────────────────

class _DashboardApprovalTile extends StatelessWidget {
  final String name;
  final String drug;
  final VoidCallback onTap;

  const _DashboardApprovalTile(
      {required this.name, required this.drug, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DoctorColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DoctorColors.statOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.pending_actions, size: 18, color: DoctorColors.statOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  Text(drug,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DoctorColors.statOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Pending',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700, color: DoctorColors.statOrange)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF5A6061)),
          ],
        ),
      ),
    );
  }
}
