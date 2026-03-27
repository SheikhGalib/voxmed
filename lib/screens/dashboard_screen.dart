import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 24),
          _buildVoiceAdherenceTracker(),
          const SizedBox(height: 16),
          _buildAppointments(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildHealthPulse()),
              const SizedBox(width: 12),
              Expanded(child: _buildDigitalPassport()),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentReports(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
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
                'Welcome back, Adrian.',
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your recovery is on track. You have 2 health tasks remaining for today and an appointment tomorrow morning.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _BannerButton(label: 'View Daily Tasks', filled: true),
                  _BannerButton(label: 'Vitals Summary', filled: false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceAdherenceTracker() {
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
                child: const Icon(Icons.settings_voice, color: AppColors.primary, size: 22),
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
                    '94%',
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
                      Text('Stable', style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                      Text('Optimal', style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAppointments() {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Appointments', style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const Icon(Icons.event, color: AppColors.onSurfaceVariant, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          _AppointmentTile(
            name: 'Dr. Sarah Jenkins',
            specialty: 'Cardiology',
            icon: Icons.person,
            date: 'Tomorrow',
            time: '09:30 AM',
            highlight: true,
          ),
          const SizedBox(height: 12),
          _AppointmentTile(
            name: 'Mental Wellness',
            specialty: 'Video Call',
            icon: Icons.video_chat,
            date: 'Oct 14',
            time: '02:00 PM',
            highlight: false,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
              ),
              child: Text('Book New', style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPulse() {
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
              const Icon(Icons.favorite, color: AppColors.onSecondaryContainer, size: 20),
              const SizedBox(width: 8),
              Text('Health Pulse', style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSecondaryContainer)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('72', style: GoogleFonts.manrope(
                fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.onSecondaryFixed)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('BPM', style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSecondaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Excellent', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSecondaryContainer)),
        ],
      ),
    );
  }

  Widget _buildDigitalPassport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
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
            child: const Icon(Icons.badge, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text('Digital Passport', style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text('Verified Credentials', style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Reports', style: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 16),
        Container(
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
                child: const Icon(Icons.description, color: AppColors.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual Blood Panel', style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Analyzed by VoxMed AI • 2 days ago', style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.download, color: AppColors.onSurfaceVariant, size: 22),
            ],
          ),
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

class _BannerButton extends StatelessWidget {
  final String label;
  final bool filled;

  const _BannerButton({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: filled ? AppColors.surfaceContainerLowest : AppColors.primaryDim.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(100),
        border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: filled ? AppColors.primary : AppColors.onPrimary,
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final String name;
  final String specialty;
  final IconData icon;
  final String date;
  final String time;
  final bool highlight;

  const _AppointmentTile({
    required this.name,
    required this.specialty,
    required this.icon,
    required this.date,
    required this.time,
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
        border: highlight ? Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.05)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: highlight ? AppColors.secondaryContainer : AppColors.surfaceContainer,
                child: Icon(icon, color: highlight ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.onSurface)),
                  Text(specialty, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
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
                  color: highlight ? AppColors.tertiaryContainer : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(date, style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: highlight ? AppColors.onTertiaryContainer : AppColors.onSurfaceVariant)),
              ),
              Text(time, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
