import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../models/medical_record.dart';
import '../providers/medical_record_provider.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class HealthPassportScreen extends ConsumerWidget {
  const HealthPassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recentMedicalRecordsProvider);
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 16, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HEALTH PASSPORT',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.primaryDim)),
          const SizedBox(height: 8),
          Text('Your medical identity, digitized and secure.',
              style: GoogleFonts.manrope(fontSize: Responsive.fontSize(context, 24), fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.2)),
          const SizedBox(height: 24),
          _buildUploadRecord(context),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: prescriptionsAsync.when(
                data: (rxList) {
                  final activeRx = rxList.where((rx) => rx.status == PrescriptionStatus.active).toList();
                  final firstItem = activeRx.isNotEmpty && activeRx.first.items != null && activeRx.first.items!.isNotEmpty
                      ? activeRx.first.items!.first : null;
                  return _buildQuickCard(
                    'Prescriptions',
                    firstItem != null ? '${firstItem.medicationName} ${firstItem.dosage}' : 'None',
                    '${activeRx.length} active',
                    Icons.medication,
                    activeRx.isNotEmpty,
                  );
                },
                loading: () => _buildQuickCard('Prescriptions', '...', 'Loading', Icons.medication, false),
                error: (_, _) => _buildQuickCard('Prescriptions', '—', 'Error', Icons.medication, false),
              )),
              const SizedBox(width: 12),
              Expanded(child: recordsAsync.when(
                data: (records) {
                  final labs = records.where((r) => r.recordType == RecordType.labResult).toList();
                  final latest = labs.isNotEmpty ? labs.first : null;
                  final daysAgo = latest?.recordDate != null ? DateTime.now().difference(latest!.recordDate!).inDays : 0;
                  return _buildQuickCard(
                    'Lab Results',
                    latest?.title ?? 'None',
                    latest != null ? 'Updated $daysAgo days ago' : 'No results',
                    Icons.science,
                    false,
                  );
                },
                loading: () => _buildQuickCard('Lab Results', '...', 'Loading', Icons.science, false),
                error: (_, _) => _buildQuickCard('Lab Results', '—', 'Error', Icons.science, false),
              )),
            ],
          ),
          const SizedBox(height: 28),
          Text('Clinical History', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 16),
          recordsAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No clinical history yet',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: List.generate(records.length, (i) {
                  final record = records[i];
                  final isUrgent = record.title.toLowerCase().contains('urgent');
                  return _buildTimelineItem(
                    context: context,
                    record: record,
                    date: record.recordDate != null ? DateFormat('MMM dd, yyyy').format(record.recordDate!).toUpperCase() : 'UNKNOWN DATE',
                    title: record.title,
                    description: record.description ?? '',
                    isFirst: i == 0,
                    isLast: i == records.length - 1,
                    urgent: isUrgent,
                  );
                }),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: GoogleFonts.inter(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRecord(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.scanRecords),
      child: Container(
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
    required BuildContext context,
    required MedicalRecord record,
    required String date,
    required String title,
    required String description,
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
            child: GestureDetector(
              onTap: () => context.push(
                '${AppRoutes.recordDetail}?recordId=${record.id}',
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
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
                    const SizedBox(height: 4),
                    Text(title,
                        style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    if (description.isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      Text(description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(record.recordType.value,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                        if (record.ocrExtracted) ...[  
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text('OCR',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
