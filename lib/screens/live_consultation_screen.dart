import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class LiveConsultationScreen extends ConsumerWidget {
  const LiveConsultationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(doctorTodayAppointmentsProvider);

    // Pick the first in-progress or upcoming appointment as the active patient
    final appointments = scheduleAsync.valueOrNull ?? [];
    final active = appointments.isNotEmpty ? appointments.first : null;
    final patientName = active?['profiles']?['full_name'] ?? 'No Patient';
    final reason = active?['reason'] ?? active?['type'] ?? 'Consultation';

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 8, Responsive.hPad(context), 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientHeader(patientName, reason),
                  const SizedBox(height: 16),
                  _buildVitalsDashboard(),
                  const SizedBox(height: 20),
                  _buildPatientComplaint(reason),
                  const SizedBox(height: 20),
                  _buildAIDifferentials(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(String name, String reason) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: const Icon(Icons.person, size: 28, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                    Text(reason,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusBadge(label: 'ACTIVE VISIT', color: AppColors.primary, bgColor: AppColors.primaryContainer.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              _StatusBadge(label: 'START PROMPTS', color: AppColors.onSurfaceVariant, bgColor: AppColors.surfaceContainerLow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2332), Color(0xFF0F1922)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('High Fidelity Audio',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 4),
          Text('REAL-TIME VITALS',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _VitalTile(label: 'HR', value: '78', unit: 'bpm', color: Colors.greenAccent)),
              Expanded(child: _VitalTile(label: 'BP', value: '158/92', unit: '', color: Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _VitalTile(label: 'SpO₂', value: '99', unit: '%', color: Colors.cyanAccent)),
              Expanded(child: _VitalTile(label: 'TEMP', value: '98.6', unit: '°F', color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientComplaint(String reason) {
    return VoxmedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('PATIENT COMPLAINT',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Patient visit reason: $reason',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('View Medications', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDifferentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('VoxMed AI Insights', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 14),
        _DifferentialCard(
          number: '1',
          title: 'Subsurface disc herniation',
          description: 'Given a trip and fall three weeks ago, it\'s mainly in the lower back area.',
          confidence: 'HIGH',
        ),
        const SizedBox(height: 10),
        _DifferentialCard(
          number: '2',
          title: 'Muscular Strain',
          description: 'Possible acute muscle irritation after the fall.',
          confidence: 'MEDIUM',
        ),
        const SizedBox(height: 10),
        _DifferentialCard(
          number: '3',
          title: 'Physical-Dynamic testing via LA scan',
          description: 'Recommend electromechanical lower back analysis. Rule out digitally compressed nerve.',
          confidence: 'SUGGEST',
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          child: Text('Review & Finalize (01:11)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: color)),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalTile({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1)),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(unit, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifferentialCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String confidence;

  const _DifferentialCard({required this.number, required this.title, required this.description, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(number, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
