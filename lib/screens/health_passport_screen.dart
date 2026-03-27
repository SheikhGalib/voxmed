import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class HealthPassportScreen extends StatelessWidget {
  const HealthPassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HEALTH PASSPORT',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.primaryDim)),
          const SizedBox(height: 8),
          Text('Your medical identity, digitized and secure.',
              style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.2)),
          const SizedBox(height: 24),
          _buildUploadRecord(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickCard('Prescriptions', 'Lisinopril 10mg', 'Since Jul, Monday', Icons.medication, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickCard('Lab Results', 'Lipid Panel', 'Updated 3 days ago', Icons.science, false)),
            ],
          ),
          const SizedBox(height: 28),
          Text('Clinical History', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 16),
          _buildTimelineItem(
            date: 'OCT 14, 2025',
            title: 'Cardiology Consultation',
            description: 'Routine check-up with Dr. Ada Thorne. Blood pressure monitoring and ECG performed.',
            tags: ['ECG REPORT.PDF', '+3 MORE'],
            isFirst: true,
          ),
          _buildTimelineItem(
            date: 'AUG 11, 2025',
            title: 'Annual Physical',
            description: 'General health assessment and immunization booster (Tdap).',
            tags: [],
          ),
          _buildTimelineItem(
            date: 'MAR 05, 2025',
            title: 'Urgent Care Visit',
            description: 'Acute respiratory infection. Prescribed course of antibiotics and 3 days rest.',
            tags: [],
            isLast: true,
            urgent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRecord() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: AppColors.onTertiaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Upload Records',
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onTertiaryContainer)),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String title, String subtitle, String meta, IconData icon, bool isActive) {
    return VoxmedCard(
      padding: const EdgeInsets.all(16),
      color: isActive ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isActive ? AppColors.primary : AppColors.onSurfaceVariant, size: 20),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('ACTIVE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(meta, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String title,
    required String description,
    List<String> tags = const [],
    bool isFirst = false,
    bool isLast = false,
    bool urgent = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: urgent ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: urgent ? AppColors.error : AppColors.onSurfaceVariant,
                      )),
                  const SizedBox(height: 6),
                  Text(title,
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
