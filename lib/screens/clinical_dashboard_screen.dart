import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class ClinicalDashboardScreen extends StatelessWidget {
  const ClinicalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildDarkStatsBar(),
            const SizedBox(height: 20),
            _buildDailySchedule(),
            const SizedBox(height: 20),
            _buildComplianceTrends(),
            const SizedBox(height: 20),
            _buildApprovalsRequired(),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkStatsBar() {
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
              Expanded(child: _StatCard(label: 'ACTIVE PATIENTS', value: '12', color: Colors.cyanAccent)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'COMPLIANCE', value: '88%', color: Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'PENDING LAB REVIEW', value: '04', color: Colors.orangeAccent)),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sarah Jenkins', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Cardiology', style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
                        ],
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

  Widget _buildDailySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Schedule', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 14),
        _ScheduleItem(time: '09:00', name: 'Sarah Jenkins', type: 'F/U Cardiology Consult', duration: '30 min'),
        _ScheduleItem(time: '10:30', name: 'Marcus Thorne', type: 'Chronic Pain Management', duration: '45 min'),
        _ScheduleItem(time: '01:00', name: 'Elena Rodriguez', type: 'Blood Work Analysis', duration: '20 min', hasImage: true),
      ],
    );
  }

  Widget _buildComplianceTrends() {
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
                    value: 0.93,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text('A+', style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Average', style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('MONTHLY ADHERENCY: 12.9%', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.88,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsRequired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Approvals Required', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 14),
        _ApprovalItem(name: 'Marcus Thorne', drug: 'Cardiology', hasAction: true),
        const SizedBox(height: 10),
        _ApprovalItem(name: 'Elena Rodriguez', drug: 'Metformin', hasAction: true),
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
  final bool hasImage;

  const _ScheduleItem({required this.time, required this.name, required this.type, required this.duration, this.hasImage = false});

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
