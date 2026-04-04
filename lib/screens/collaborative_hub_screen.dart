import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class CollaborativeHubScreen extends ConsumerWidget {
  const CollaborativeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(consultationSessionsProvider);

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
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_off, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No active consultations', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Use the first session as the active one
          final session = sessions.first;
          final cs = session['consultation_sessions'] as Map<String, dynamic>? ?? {};
          final patientName = (cs['profiles'] as Map<String, dynamic>?)?['full_name'] ?? 'Unknown Patient';
          final patientId = cs['id']?.toString() ?? '';
          final sessionTitle = cs['title'] ?? 'Consultation';
          final notes = cs['notes'] ?? '';
          final soapNote = cs['soap_note'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientCard(patientName, patientId),
                const SizedBox(height: 16),
                _buildVitalsRow(ref, cs),
                const SizedBox(height: 20),
                _buildCollaborativeExchange(),
                const SizedBox(height: 20),
                _buildClinicalHistory(sessionTitle, soapNote),
                const SizedBox(height: 20),
                _buildAssignedSpecialists(soapNote),
                const SizedBox(height: 20),
                _buildTreatmentThread(notes),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('Failed to load consultations', style: GoogleFonts.inter(color: AppColors.error))),
      ),
    );
  }

  Widget _buildPatientCard(String name, String patientId) {
    return VoxmedCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondaryContainer,
                child: const Icon(Icons.person, size: 28, color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                    Text('Session: ${patientId.length > 8 ? patientId.substring(0, 8) : patientId}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Badge(label: 'GENERATE REPORT', color: AppColors.primary, bgColor: AppColors.primaryContainer.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              _Badge(label: 'START PROMPTS', color: AppColors.onSurfaceVariant, bgColor: AppColors.surfaceContainerLow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(WidgetRef ref, Map<String, dynamic> cs) {
    // Show vitals from the consultation session if available
    final soapNote = cs['soap_note'] as Map<String, dynamic>? ?? {};
    final vitals = soapNote['vitals'] as Map<String, dynamic>? ?? {};
    final hr = vitals['heart_rate']?.toString() ?? '—';
    final bp = vitals['blood_pressure']?.toString() ?? '—';
    final spo2 = vitals['spo2']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REAL-TIME VITALS',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _VitalChip(label: 'HR', value: hr, unit: 'bpm')),
              const SizedBox(width: 8),
              Expanded(child: _VitalChip(label: 'BP', value: bp, unit: '')),
              const SizedBox(width: 8),
              Expanded(child: _VitalChip(label: 'SpO₂', value: spo2, unit: '%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeExchange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Collaborative Exchange',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Securely share records via FHIR-based API with external specialists for peer review and collaborative analysis.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.security, size: 16),
            label: Text('Secure File Share', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalHistory(String title, Map<String, dynamic> soapNote) {
    final diagnosis = soapNote['assessment']?.toString() ?? title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Text('Clinical History',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(diagnosis,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text('Active consultation',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedSpecialists(Map<String, dynamic> soapNote) {
    final plan = soapNote['plan']?.toString() ?? 'No lab data available';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group, color: AppColors.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Text('Labs',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treatment Plan', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    Text(plan, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentThread(String notes) {
    final displayText = notes.isNotEmpty
        ? notes
        : 'No treatment collaboration notes yet. Start a discussion to coordinate care.';

    return VoxmedCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.2),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Treatment Collaboration Thread',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayText,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({required this.label, required this.color, required this.bgColor});

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

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalChip({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(unit, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
