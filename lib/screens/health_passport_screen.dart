import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../models/medical_record.dart';
import '../models/prescription.dart';
import '../providers/medical_record_provider.dart';
import '../providers/prescription_provider.dart';
import '../widgets/voxmed_card.dart';

class HealthPassportScreen extends ConsumerStatefulWidget {
  const HealthPassportScreen({super.key});

  @override
  ConsumerState<HealthPassportScreen> createState() => _HealthPassportScreenState();
}

class _HealthPassportScreenState extends ConsumerState<HealthPassportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabLabels = ['All', 'Prescriptions', 'Reports', 'Lab Results'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  return GestureDetector(
                    onTap: activeRx.isNotEmpty ? () => _showPrescriptionDetail(context, activeRx.first) : null,
                    child: _buildQuickCard(
                      'Prescriptions',
                      firstItem != null ? '${firstItem.medicationName} ${firstItem.dosage}' : 'None',
                      '${activeRx.length} active Â· tap to view',
                      Icons.medication,
                      activeRx.isNotEmpty,
                    ),
                  );
                },
                loading: () => _buildQuickCard('Prescriptions', '...', 'Loading', Icons.medication, false),
                error: (_, _) => _buildQuickCard('Prescriptions', 'â€”', 'Error', Icons.medication, false),
              )),
              const SizedBox(width: 12),
              Expanded(child: recordsAsync.when(
                data: (records) {
                  final labs = records.where((r) => r.recordType == RecordType.labResult).toList();
                  final latest = labs.isNotEmpty ? labs.first : null;
                  final daysAgo = latest?.recordDate != null ? DateTime.now().difference(latest!.recordDate!).inDays : 0;
                  return GestureDetector(
                    onTap: latest != null
                        ? () => context.push('${AppRoutes.recordDetail}?recordId=${latest.id}')
                        : null,
                    child: _buildQuickCard(
                      'Lab Results',
                      latest?.title ?? 'None',
                      latest != null ? 'Updated $daysAgo days ago' : 'No results',
                      Icons.science,
                      false,
                    ),
                  );
                },
                loading: () => _buildQuickCard('Lab Results', '...', 'Loading', Icons.science, false),
                error: (_, _) => _buildQuickCard('Lab Results', 'â€”', 'Error', Icons.science, false),
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

          // â”€â”€ Records Browser â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const SizedBox(height: 32),
          Text('Records', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _buildRecordsTabs(context, recordsAsync, prescriptionsAsync),
        ],
      ),
    );
  }

  // â”€â”€ Records Tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRecordsTabs(
    BuildContext context,
    AsyncValue<List<MedicalRecord>> recordsAsync,
    AsyncValue<List<Prescription>> prescriptionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final tab = _tabController.index;
            return _buildTabContent(context, tab, recordsAsync, prescriptionsAsync);
          },
        ),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    int tab,
    AsyncValue<List<MedicalRecord>> recordsAsync,
    AsyncValue<List<Prescription>> prescriptionsAsync,
  ) {
    // Tab 0 = All, Tab 1 = Prescriptions, Tab 2 = Reports, Tab 3 = Lab Results
    if (tab == 1) {
      return prescriptionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox(),
        data: (rxList) => _buildPrescriptionList(context, rxList),
      );
    }

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox(),
      data: (records) {
        late List items;
        if (tab == 0) {
          // All: prescriptions first, then records
          final allRx = prescriptionsAsync.valueOrNull ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allRx.isNotEmpty) ...[
                _buildPrescriptionList(context, allRx),
                const SizedBox(height: 12),
              ],
              ...records.map((r) => _buildRecordTile(context, r)),
            ],
          );
        } else if (tab == 2) {
          items = records.where((r) =>
              r.recordType != RecordType.labResult &&
              r.recordType != RecordType.prescription).toList();
        } else {
          items = records.where((r) => r.recordType == RecordType.labResult).toList();
        }

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No records here yet.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
            ),
          );
        }
        return Column(
          children: (items as List<MedicalRecord>).map((r) => _buildRecordTile(context, r)).toList(),
        );
      },
    );
  }

  Widget _buildPrescriptionList(BuildContext context, List<Prescription> rxList) {
    if (rxList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No prescriptions yet.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: rxList.map((rx) => _buildPrescriptionTile(context, rx)).toList(),
    );
  }

  Widget _buildPrescriptionTile(BuildContext context, Prescription rx) {
    final statusColor = rx.status == PrescriptionStatus.active ? AppColors.primary : AppColors.onSurfaceVariant;
    final itemCount = rx.items?.length ?? 0;
    return GestureDetector(
      onTap: () => _showPrescriptionDetail(context, rx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medication, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rx.diagnosis ?? 'Prescription',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rx.doctorName != null ? 'Dr. ${rx.doctorName}' : 'Unknown doctor'} Â· $itemCount medication${itemCount == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy').format(rx.issuedDate),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rx.status.value.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: statusColor),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(BuildContext context, MedicalRecord record) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.recordDetail}?recordId=${record.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_recordIcon(record.recordType), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.title,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_typeLabel(record.recordType.value),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      if (record.ocrExtracted) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.auto_awesome, size: 11, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text('OCR', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  if (record.recordDate != null)
                    Text(DateFormat('MMM dd, yyyy').format(record.recordDate!),
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  IconData _recordIcon(RecordType type) {
    switch (type) {
      case RecordType.labResult: return Icons.science;
      case RecordType.radiology: return Icons.radio;
      case RecordType.prescription: return Icons.medication;
      case RecordType.consultationNote: return Icons.notes;
      case RecordType.dischargeSummary: return Icons.summarize;
      default: return Icons.insert_drive_file;
    }
  }

  String _typeLabel(String key) {
    const labels = {
      'prescription': 'Prescription',
      'lab_result': 'Lab Result',
      'radiology': 'Radiology',
      'discharge_summary': 'Discharge Summary',
      'consultation_note': 'Consultation Note',
      'other': 'Other',
    };
    return labels[key] ?? key;
  }

  void _showPrescriptionDetail(BuildContext context, Prescription rx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrescriptionDetailSheet(prescription: rx),
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
              const Icon(Icons.chevron_right, size: 14, color: AppColors.onSurfaceVariant),
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

// â”€â”€ Prescription Detail Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PrescriptionDetailSheet extends StatelessWidget {
  final Prescription prescription;
  const _PrescriptionDetailSheet({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final rx = prescription;
    final items = rx.items ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.medication, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rx.diagnosis ?? 'Prescription',
                              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                            ),
                            if (rx.doctorName != null)
                              Text('Dr. ${rx.doctorName}${rx.doctorSpecialty != null ? ' Â· ${rx.doctorSpecialty}' : ''}',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Meta row
                  Row(
                    children: [
                      _MetaChip(label: 'Issued', value: DateFormat('MMM dd, yyyy').format(rx.issuedDate)),
                      const SizedBox(width: 8),
                      _MetaChip(
                        label: 'Status',
                        value: rx.status.value.toUpperCase(),
                        color: rx.status == PrescriptionStatus.active ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                      if (rx.validUntil != null) ...[
                        const SizedBox(width: 8),
                        _MetaChip(label: 'Valid until', value: DateFormat('MMM dd, yyyy').format(rx.validUntil!)),
                      ],
                    ],
                  ),

                  if (rx.notes != null && rx.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(rx.notes!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Text('Medications',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 12),

                  if (items.isEmpty)
                    Text('No medications listed.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant))
                  else
                    ...items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8, height: 8, margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.medicationName} ${item.dosage}',
                                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                                const SizedBox(height: 2),
                                Text(item.frequency,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                if (item.instructions != null && item.instructions!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(item.instructions!,
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MetaChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.onSurfaceVariant).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color ?? AppColors.onSurface)),
        ],
      ),
    );
  }
}
