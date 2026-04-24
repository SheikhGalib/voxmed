import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../models/prescription.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(currentDoctorProvider);
    final rxAsync = ref.watch(patientPrescriptionsByIdProvider(widget.patientId));
    final recordsAsync = ref.watch(patientRecordsByIdProvider(widget.patientId));

    return doctorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text(e.toString()))),
      data: (doctor) {
        if (doctor == null) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        final visitsAsync = ref.watch(patientVisitsForDoctorProvider(
          (doctorId: doctor.id, patientId: widget.patientId),
        ));

        // Derive patient name from first appointment
        final patientName = visitsAsync.valueOrNull?.firstOrNull?.patientName ??
            rxAsync.valueOrNull?.firstOrNull?.patientId.substring(0, 8) ??
            'Patient';

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(patientName),
              _buildTabBar(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  visitsAsync: visitsAsync,
                  rxAsync: rxAsync,
                  recordsAsync: recordsAsync,
                ),
                _PrescriptionsTab(
                  patientId: widget.patientId,
                  doctorId: doctor.id,
                  rxAsync: rxAsync,
                  onPrescriptionCreated: () {
                    ref.refresh(patientPrescriptionsByIdProvider(widget.patientId));
                  },
                ),
                _RecordsTab(recordsAsync: recordsAsync),
                _AnalyticsTab(visitsAsync: visitsAsync, rxAsync: rxAsync),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(String patientName) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: BackButton(color: AppColors.onSurface),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        title: Text(patientName,
            style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface)),
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(patientName,
                        style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface)),
                    Text('Patient',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 13),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Records'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── OVERVIEW TAB ───────────────────────

class _OverviewTab extends StatelessWidget {
  final AsyncValue<List<Appointment>> visitsAsync;
  final AsyncValue<List<Prescription>> rxAsync;
  final AsyncValue<List<MedicalRecord>> recordsAsync;

  const _OverviewTab({
    required this.visitsAsync,
    required this.rxAsync,
    required this.recordsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Visit Summary',
          icon: Icons.calendar_month_outlined,
          child: visitsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load visits'),
            data: (visits) {
              final total = visits.length;
              final completed =
                  visits.where((v) => v.status == AppointmentStatus.completed).length;
              final upcoming = visits
                  .where((v) =>
                      v.status == AppointmentStatus.scheduled ||
                      v.status == AppointmentStatus.confirmed)
                  .length;
              return Row(
                children: [
                  _StatBubble(label: 'Total', value: '$total', color: AppColors.primary),
                  const SizedBox(width: 12),
                  _StatBubble(
                      label: 'Completed',
                      value: '$completed',
                      color: const Color(0xFF0D6EFD)),
                  const SizedBox(width: 12),
                  _StatBubble(
                      label: 'Upcoming',
                      value: '$upcoming',
                      color: const Color(0xFFE0962A)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Active Prescriptions',
          icon: Icons.medication_outlined,
          child: rxAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load prescriptions'),
            data: (rxList) {
              final active =
                  rxList.where((r) => r.status == PrescriptionStatus.active).toList();
              if (active.isEmpty) {
                return Text('No active prescriptions',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant));
              }
              return Column(
                children: active.take(3).map((rx) {
                  final items = rx.items ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            items.isNotEmpty
                                ? items.map((i) => i.medicationName).join(', ')
                                : rx.diagnosis ?? 'Prescription',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM').format(rx.issuedDate),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Recent Records',
          icon: Icons.folder_outlined,
          child: recordsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load records'),
            data: (records) {
              if (records.isEmpty) {
                return Text('No records',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant));
              }
              return Column(
                children: records.take(3).map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_outlined,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(r.recordType.value,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // AI summary box
        _SectionCard(
          title: 'Patient Summary',
          icon: Icons.auto_awesome_outlined,
          child: _PatientSummaryText(
            visitsAsync: visitsAsync,
            rxAsync: rxAsync,
            recordsAsync: recordsAsync,
          ),
        ),
      ],
    );
  }
}

class _PatientSummaryText extends StatelessWidget {
  final AsyncValue<List<Appointment>> visitsAsync;
  final AsyncValue<List<Prescription>> rxAsync;
  final AsyncValue<List<MedicalRecord>> recordsAsync;

  const _PatientSummaryText({
    required this.visitsAsync,
    required this.rxAsync,
    required this.recordsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final visits = visitsAsync.valueOrNull ?? [];
    final rxList = rxAsync.valueOrNull ?? [];
    final records = recordsAsync.valueOrNull ?? [];

    if (visits.isEmpty && rxList.isEmpty && records.isEmpty) {
      return Text('No data available yet.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant));
    }

    final medications = rxList
        .expand((rx) => rx.items ?? [])
        .map((i) => i.medicationName)
        .toSet()
        .toList();
    final diagnoses = rxList
        .where((rx) => rx.diagnosis != null)
        .map((rx) => rx.diagnosis!)
        .toSet()
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('Total visits: ${visits.length}');
    if (diagnoses.isNotEmpty) {
      buffer.writeln('Known conditions: ${diagnoses.take(3).join(', ')}');
    }
    if (medications.isNotEmpty) {
      buffer.writeln(
          'Medications used: ${medications.take(5).join(', ')}${medications.length > 5 ? '…' : ''}');
    }
    if (records.isNotEmpty) {
      buffer.writeln('Lab records on file: ${records.length}');
    }

    return Text(buffer.toString().trim(),
        style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: AppColors.onSurface));
  }
}

// ─────────────────────── PRESCRIPTIONS TAB ───────────────────────

class _PrescriptionsTab extends ConsumerWidget {
  final String patientId;
  final String doctorId;
  final AsyncValue<List<Prescription>> rxAsync;
  final VoidCallback onPrescriptionCreated;

  const _PrescriptionsTab({
    required this.patientId,
    required this.doctorId,
    required this.rxAsync,
    required this.onPrescriptionCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWritePrescriptionSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Write Prescription',
            style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: rxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rxList) {
          if (rxList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 52,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No prescriptions yet',
                      style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: rxList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _PrescriptionCard(rx: rxList[i]),
          );
        },
      ),
    );
  }

  void _showWritePrescriptionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WritePrescriptionSheet(
        patientId: patientId,
        doctorId: doctorId,
        onCreated: () {
          onPrescriptionCreated();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Prescription rx;

  const _PrescriptionCard({required this.rx});

  @override
  Widget build(BuildContext context) {
    final items = rx.items ?? [];
    final statusColor = rx.status == PrescriptionStatus.active
        ? AppColors.primary
        : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Expanded(
                child: Text(
                  rx.diagnosis ?? 'Prescription',
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rx.status.value,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('d MMM yyyy').format(rx.issuedDate),
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.medication, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.onSurface),
                            children: [
                              TextSpan(
                                  text: item.medicationName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              TextSpan(
                                  text:
                                      ' · ${item.dosage} · ${item.frequency}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (rx.notes != null) ...[
            const SizedBox(height: 6),
            Text(rx.notes!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────── WRITE PRESCRIPTION SHEET ───────────────────────

class _WritePrescriptionSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String doctorId;
  final VoidCallback onCreated;

  const _WritePrescriptionSheet({
    required this.patientId,
    required this.doctorId,
    required this.onCreated,
  });

  @override
  ConsumerState<_WritePrescriptionSheet> createState() =>
      _WritePrescriptionSheetState();
}

class _WritePrescriptionSheetState
    extends ConsumerState<_WritePrescriptionSheet> {
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_MedItem> _medications = [_MedItem()];
  bool _saving = false;

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    for (final m in _medications) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text('Write Prescription',
                    style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(_diagnosisCtrl, 'Diagnosis', Icons.medical_information_outlined),
                  const SizedBox(height: 12),
                  _field(_notesCtrl, 'Notes (optional)', Icons.notes_outlined, maxLines: 2),
                  const SizedBox(height: 20),
                  Text('Medications',
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 10),
                  ...List.generate(_medications.length, (i) {
                    return _MedItemWidget(
                      key: ValueKey(i),
                      item: _medications[i],
                      onRemove: _medications.length > 1
                          ? () => setState(() => _medications.removeAt(i))
                          : null,
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() => _medications.add(_MedItem())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add medication',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Prescription',
                              style: GoogleFonts.manrope(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a diagnosis')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(createPrescriptionProvider.notifier);
      final items = _medications
          .where((m) => m.nameCtrl.text.trim().isNotEmpty)
          .map((m) => {
                'medication_name': m.nameCtrl.text.trim(),
                'dosage': m.dosageCtrl.text.trim(),
                'frequency': m.frequencyCtrl.text.trim(),
                if (m.durCtrl.text.trim().isNotEmpty)
                  'duration_days': int.tryParse(m.durCtrl.text.trim()),
                if (m.instrCtrl.text.trim().isNotEmpty)
                  'instructions': m.instrCtrl.text.trim(),
              })
          .toList();

      final success = await notifier.createPrescription(
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        diagnosis: _diagnosisCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: items,
      );

      if (success && mounted) {
        widget.onCreated();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save prescription')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MedItem {
  final nameCtrl = TextEditingController();
  final dosageCtrl = TextEditingController();
  final frequencyCtrl = TextEditingController();
  final durCtrl = TextEditingController();
  final instrCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    durCtrl.dispose();
    instrCtrl.dispose();
  }
}

class _MedItemWidget extends StatelessWidget {
  final _MedItem item;
  final VoidCallback? onRemove;

  const _MedItemWidget({super.key, required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniField(item.nameCtrl, 'Medication name'),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: AppColors.error),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniField(item.dosageCtrl, 'Dosage (e.g. 500mg)')),
              const SizedBox(width: 8),
              Expanded(child: _miniField(item.frequencyCtrl, 'Frequency')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniField(item.durCtrl, 'Duration (days)', isNumber: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniField(item.instrCtrl, 'Instructions')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : null,
      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }
}

// ─────────────────────── RECORDS TAB ───────────────────────

class _RecordsTab extends StatelessWidget {
  final AsyncValue<List<MedicalRecord>> recordsAsync;

  const _RecordsTab({required this.recordsAsync});

  @override
  Widget build(BuildContext context) {
    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open,
                    size: 52,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No records on file',
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _RecordCard(record: records[i]),
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  '${record.recordType.value} · ${DateFormat('d MMM yyyy').format(record.createdAt.toLocal())}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                if (record.description != null)
                  Text(record.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (record.fileUrl != null)
            const Icon(Icons.attach_file,
                size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ─────────────────────── ANALYTICS TAB ───────────────────────

class _AnalyticsTab extends StatelessWidget {
  final AsyncValue<List<Appointment>> visitsAsync;
  final AsyncValue<List<Prescription>> rxAsync;

  const _AnalyticsTab({required this.visitsAsync, required this.rxAsync});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Visit Frequency (Last 6 Months)',
          icon: Icons.bar_chart_outlined,
          child: visitsAsync.when(
            loading: () => const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load chart data'),
            data: (visits) => _VisitBarChart(visits: visits),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Medication History',
          icon: Icons.medication_outlined,
          child: rxAsync.when(
            loading: () => const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load data'),
            data: (rxList) => _MedicationHistory(rxList: rxList),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Appointment Types',
          icon: Icons.pie_chart_outline,
          child: visitsAsync.when(
            loading: () => const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load chart data'),
            data: (visits) => _AppointmentTypePie(visits: visits),
          ),
        ),
      ],
    );
  }
}

class _VisitBarChart extends StatelessWidget {
  final List<Appointment> visits;

  const _VisitBarChart({required this.visits});

  @override
  Widget build(BuildContext context) {
    // Group visits by month for the last 6 months.
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return d;
    });

    final counts = months.map((m) {
      return visits
          .where((v) =>
              v.scheduledStartAt.year == m.year &&
              v.scheduledStartAt.month == m.month)
          .length
          .toDouble();
    }).toList();

    final maxY = counts.reduce((a, b) => a > b ? a : b);

    if (maxY == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No visits in the last 6 months',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.onSurfaceVariant)),
      );
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('MMM').format(months[i]),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.onSurfaceVariant),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble() && value > 0) {
                    return Text(
                      '${value.toInt()}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.onSurfaceVariant),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            6,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i],
                  color: AppColors.primary,
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationHistory extends StatelessWidget {
  final List<Prescription> rxList;

  const _MedicationHistory({required this.rxList});

  @override
  Widget build(BuildContext context) {
    // Aggregate medication names with frequency.
    final Map<String, int> freq = {};
    for (final rx in rxList) {
      for (final item in rx.items ?? []) {
        freq[item.medicationName] = (freq[item.medicationName] ?? 0) + 1;
      }
    }

    if (freq.isEmpty) {
      return Text('No medication history',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.onSurfaceVariant));
    }

    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Column(
      children: sorted.take(6).map((e) {
        final pct = e.value / maxVal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.onSurface)),
                  Text('×${e.value}',
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AppointmentTypePie extends StatelessWidget {
  final List<Appointment> visits;

  const _AppointmentTypePie({required this.visits});

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) {
      return Text('No data',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.onSurfaceVariant));
    }

    final inPerson = visits
        .where((v) => v.type == AppointmentType.inPerson)
        .length
        .toDouble();
    final video =
        visits.where((v) => v.type == AppointmentType.video).length.toDouble();
    final followUp =
        visits.where((v) => v.type == AppointmentType.followUp).length.toDouble();
    final total = visits.length.toDouble();

    final sections = <PieChartSectionData>[
      if (inPerson > 0)
        PieChartSectionData(
          value: inPerson,
          color: AppColors.primary,
          title: '${(inPerson / total * 100).round()}%',
          titleStyle: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white),
          radius: 60,
        ),
      if (video > 0)
        PieChartSectionData(
          value: video,
          color: const Color(0xFF0D6EFD),
          title: '${(video / total * 100).round()}%',
          titleStyle: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white),
          radius: 60,
        ),
      if (followUp > 0)
        PieChartSectionData(
          value: followUp,
          color: const Color(0xFFE0962A),
          title: '${(followUp / total * 100).round()}%',
          titleStyle: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white),
          radius: 60,
        ),
    ];

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 32,
          )),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: AppColors.primary, label: 'In-person', count: inPerson.toInt()),
            const SizedBox(height: 8),
            _Legend(color: const Color(0xFF0D6EFD), label: 'Video', count: video.toInt()),
            const SizedBox(height: 8),
            _Legend(color: const Color(0xFFE0962A), label: 'Follow-up', count: followUp.toInt()),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface)),
      ],
    );
  }
}

// ─────────────────────── SHARED WIDGETS ───────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBubble({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── TAB BAR DELEGATE ───────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.surface, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
