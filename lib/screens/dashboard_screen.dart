import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/medical_record_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/voxmed_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final adherenceAsync = ref.watch(adherenceStatsProvider);
    final wearableAsync = ref.watch(wearableDataProvider);
    final recordsAsync = ref.watch(recentMedicalRecordsProvider);

    final firstName = profileAsync.when(
      data: (p) => p?.fullName.split(' ').first ?? 'User',
      loading: () => '...',
      error: (_, _) => 'User',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(firstName, ref),
          const SizedBox(height: 24),
          _buildVoiceAdherenceTracker(adherenceAsync),
          const SizedBox(height: 16),
          _buildUpcomingAppointments(context, ref),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildHealthPulse(wearableAsync)),
              const SizedBox(width: 12),
              Expanded(child: _buildDigitalPassport()),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentReports(recordsAsync),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String firstName, WidgetRef ref) {
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider);
    final nextApptText = appointmentsAsync.when(
      data: (appts) {
        if (appts.isEmpty) return 'No upcoming appointments.';
        final next = appts.first;
        final diff = next.scheduledStartAt.difference(DateTime.now());
        if (diff.inDays == 0) return 'You have an appointment today.';
        if (diff.inDays == 1) return 'You have an appointment tomorrow.';
        return 'Next appointment in ${diff.inDays} days.';
      },
      loading: () => '',
      error: (_, _) => '',
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDim],
        ),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            bottom: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName.',
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your recovery is on track. $nextApptText',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.passport),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Health Passport',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.health),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            'Vitals Summary',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceAdherenceTracker(
    AsyncValue<Map<String, dynamic>> adherenceAsync,
  ) {
    final rate = adherenceAsync.when(
      data: (stats) => '${stats['rate'] ?? 0}%',
      loading: () => '...',
      error: (_, _) => '—',
    );

    return VoxmedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE MONITORING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primaryDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Voice Adherence Tracker',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.settings_voice,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildWaveform()),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rate,
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Clarity Score',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TONE ANALYSIS', style: _chipLabel),
                      const SizedBox(height: 4),
                      Text(
                        'Stable',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESPIRATION', style: _chipLabel),
                      const SizedBox(height: 4),
                      Text(
                        'Optimal',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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

  Widget _buildWaveform() {
    final heights = [0.4, 0.6, 1.0, 0.7, 0.45, 0.65, 0.3, 0.5, 0.55];
    final opacities = [0.2, 0.4, 1.0, 0.8, 0.6, 0.9, 0.3, 0.7, 0.5];
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FractionallySizedBox(
                heightFactor: heights[i],
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: opacities[i]),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Appointments',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(upcomingAppointmentsProvider),
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          appointmentsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: VoxmedLoadingIndicator(message: 'Loading appointments...'),
            ),
            error: (error, _) => VoxmedErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(upcomingAppointmentsProvider),
            ),
            data: (appointments) {
              if (appointments.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.event_busy,
                  title: 'No upcoming appointments',
                  subtitle: 'Book a consultation from Find Care.',
                  buttonText: 'Find Care',
                  onButtonPressed: () => context.go(AppRoutes.findCare),
                );
              }

              return Column(
                children: [
                  for (
                    int index = 0;
                    index < appointments.take(3).length;
                    index++
                  ) ...[
                    _UpcomingAppointmentTile(
                      appointment: appointments[index],
                      highlight: index == 0,
                    ),
                    if (index < appointments.take(3).length - 1)
                      const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.findCare),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Book New Appointment',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPulse(AsyncValue<Map<String, dynamic>> wearableAsync) {
    final bpm = wearableAsync.when(
      data: (data) {
        final hrList = data['heart_rate'] as List? ?? [];
        if (hrList.isEmpty) return '--';
        final val = hrList.first['value'];
        if (val is Map) return '${val['bpm'] ?? '--'}';
        return '--';
      },
      loading: () => '...',
      error: (_, _) => '--',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: AppColors.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Health Pulse',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bpm,
                style: GoogleFonts.manrope(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSecondaryFixed,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'BPM',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Excellent',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalPassport() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => context.go(AppRoutes.passport),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.badge,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Digital Passport',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified Credentials',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.chevron_right, color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentReports(AsyncValue<List<MedicalRecord>> recordsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reports',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        recordsAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: VoxmedLoadingIndicator(message: 'Loading reports...'),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Could not load reports',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          data: (records) {
            if (records.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No recent reports',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: records.take(3).map<Widget>((record) {
                final daysAgo = record.recordDate != null
                    ? DateTime.now().difference(record.recordDate!).inDays
                    : 0;
                final timeText = daysAgo == 0
                    ? 'Today'
                    : daysAgo == 1
                    ? 'Yesterday'
                    : '$daysAgo days ago';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            record.recordType == RecordType.labResult
                                ? Icons.biotech
                                : Icons.description,
                            color: AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Uploaded • $timeText',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (record.fileUrl != null)
                          const Icon(
                            Icons.download,
                            color: AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  static TextStyle get _chipLabel => GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.onSurfaceVariant,
  );
}

// _BannerButton removed — buttons are now inline GestureDetectors with navigation.

class _UpcomingAppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool highlight;

  const _UpcomingAppointmentTile({
    required this.appointment,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.05),
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: highlight
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainer,
                child: Icon(
                  appointment.type == AppointmentType.video
                      ? Icons.videocam
                      : Icons.medical_services,
                  color: highlight
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName ?? 'Doctor',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    appointment.doctorSpecialty ?? 'General consultation',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: highlight
                      ? AppColors.tertiaryContainer
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat(
                    'MMM d',
                  ).format(appointment.scheduledStartAt.toLocal()),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? AppColors.onTertiaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                DateFormat(
                  'hh:mm a',
                ).format(appointment.scheduledStartAt.toLocal()),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (appointment.type == AppointmentType.video)
                GestureDetector(
                  onTap: () {
                    context.push(
                      '${AppRoutes.videoCall}?roomId=room_${appointment.id}&videoCallId=',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Join',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
}
