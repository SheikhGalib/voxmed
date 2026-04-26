import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/supabase_config.dart';
import '../core/theme/app_colors.dart';
import '../models/medication_schedule.dart';
import '../models/prescription.dart';
import '../providers/medication_schedule_provider.dart';
import '../providers/prescription_provider.dart';
import '../repositories/notification_service.dart';

class MedicationScheduleScreen extends ConsumerStatefulWidget {
  const MedicationScheduleScreen({super.key});

  @override
  ConsumerState<MedicationScheduleScreen> createState() =>
      _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState
    extends ConsumerState<MedicationScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);
    final schedulesAsync = ref.watch(medicationSchedulesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Schedule Medicine',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: prescriptionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load prescriptions',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant))),
        data: (prescriptions) {
          final activeItems = prescriptions
              .expand((p) => p.items ?? <PrescriptionItem>[])
              .toList();

          if (activeItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medication_outlined,
                        size: 64, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('No prescriptions yet',
                        style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    Text(
                        'Ask your doctor to add prescriptions. '
                        'Then come back here to set up reminders.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            height: 1.5)),
                  ],
                ),
              ),
            );
          }

          final existingSchedules = schedulesAsync.valueOrNull ?? [];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final item = activeItems[i];
              final existing = existingSchedules
                  .where((s) => s.prescriptionItemId == item.id)
                  .firstOrNull;
              return _PrescriptionScheduleCard(
                item: item,
                existing: existing,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Card per prescription item ─────────────────────

class _PrescriptionScheduleCard extends ConsumerStatefulWidget {
  final PrescriptionItem item;
  final MedicationSchedule? existing;

  const _PrescriptionScheduleCard({required this.item, this.existing});

  @override
  ConsumerState<_PrescriptionScheduleCard> createState() =>
      _PrescriptionScheduleCardState();
}

class _PrescriptionScheduleCardState
    extends ConsumerState<_PrescriptionScheduleCard> {
  late List<String> _times;
  late List<bool> _days; // index 0 = Mon (weekday 1) … index 6 = Sun (7)
  bool _isSaving = false;
  bool _isExpanded = false;
  bool _isAutoEnabling = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Derives sensible default reminder times from a free-text frequency string.
  static List<String> _defaultTimesFromFrequency(String frequency) {
    final f = frequency.toLowerCase();
    if (f.contains('three') || f.contains('3') || f.contains('thrice') || f.contains('tid')) {
      return ['08:00', '14:00', '20:00'];
    }
    if (f.contains('twice') || f.contains('two') || f.contains('2') || f.contains('bid')) {
      return ['08:00', '20:00'];
    }
    if (f.contains('four') || f.contains('4') || f.contains('qid')) {
      return ['08:00', '12:00', '16:00', '20:00'];
    }
    return ['08:00']; // once daily default
  }

  @override
  void initState() {
    super.initState();
    _times = List<String>.from(widget.existing?.timesOfDay ?? ['08:00']);
    _days = List.generate(7, (i) {
      if (widget.existing == null) return true; // default: every day
      return widget.existing!.daysOfWeek == null
          ? true
          : widget.existing!.daysOfWeek!.contains(i + 1);
    });
  }

  List<int>? _selectedDays() {
    if (_days.every((d) => d)) return null; // null = every day
    final list = <int>[];
    for (var i = 0; i < 7; i++) {
      if (_days[i]) list.add(i + 1); // 1=Mon … 7=Sun
    }
    return list.isEmpty ? null : list;
  }

  Future<void> _autoEnable() async {
    setState(() => _isAutoEnabling = true);
    try {
      final granted = await NotificationService().requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied. Reminders may not appear.')),
        );
      }
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not signed in');

      final defaultTimes = _defaultTimesFromFrequency(widget.item.frequency);
      final schedule = MedicationSchedule(
        id: '',
        patientId: uid,
        prescriptionItemId: widget.item.id,
        medicationName: widget.item.medicationName,
        dosage: widget.item.dosage,
        frequency: widget.item.frequency,
        timesOfDay: defaultTimes,
        daysOfWeek: null, // every day
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(medicationScheduleNotifierProvider.notifier).create(schedule);
      if (mounted) {
        // Update local state to reflect auto-assigned times
        setState(() {
          _times = defaultTimes;
          _isExpanded = true; // open to show customise options
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-schedule enabled for ${widget.item.medicationName}!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAutoEnabling = false);
    }
  }

  Future<void> _autoDisable() async {
    if (widget.existing == null) return;
    await ref.read(medicationScheduleNotifierProvider.notifier).delete(widget.existing!.id);
    if (mounted) {
      setState(() => _isExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule disabled.')),
      );
    }
  }

  Future<void> _pickTime(int index) async {
    final parts = _times[index].split(':');
    final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      _times[index] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    // Request permissions first
    final granted = await NotificationService().requestPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Notification permission denied. Reminders may not appear.')),
      );
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(medicationScheduleNotifierProvider.notifier);

      if (widget.existing != null) {
        await notifier.update(widget.existing!.copyWith(
          timesOfDay: _times,
          daysOfWeek: _selectedDays(),
        ));
      } else {
        final uid = supabase.auth.currentUser?.id;
        if (uid == null) {
          throw Exception('Not signed in');
        }

        final schedule = MedicationSchedule(
          id: '',
          patientId: uid,
          prescriptionItemId: widget.item.id,
          medicationName: widget.item.medicationName,
          dosage: widget.item.dosage,
          frequency: widget.item.frequency,
          timesOfDay: _times,
          daysOfWeek: _selectedDays(),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await notifier.create(schedule);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reminders set for ${widget.item.medicationName}!'),
              backgroundColor: AppColors.primary),
        );
        setState(() => _isExpanded = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref
        .read(medicationScheduleNotifierProvider.notifier)
        .delete(widget.existing!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSchedule = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSchedule
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          GestureDetector(
            onTap: hasSchedule ? () => setState(() => _isExpanded = !_isExpanded) : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasSchedule
                          ? AppColors.primaryContainer.withValues(alpha: 0.3)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasSchedule ? Icons.alarm_on : Icons.alarm_add,
                      color: hasSchedule
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.medicationName,
                            style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.item.dosage} · ${widget.item.frequency}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant),
                        ),
                        if (hasSchedule) ...[
                          const SizedBox(height: 4),
                          Text(
                            '⏰ ${widget.existing!.timesOfDay.join(', ')}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Auto-scheduler toggle
                  _isAutoEnabling
                      ? const SizedBox(
                          width: 36,
                          height: 20,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Switch(
                          value: hasSchedule,
                          onChanged: (on) {
                            if (on) {
                              _autoEnable();
                            } else {
                              _autoDisable();
                            }
                          },
                        ),
                  if (hasSchedule)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && hasSchedule) ...[
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder times',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_times.length, (i) {
                      return GestureDetector(
                        onTap: () => _pickTime(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(_times[i],
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                              if (_times.length > 1) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _times.removeAt(i)),
                                  child: const Icon(Icons.close,
                                      size: 14, color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_times.length < 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _times.add('12:00'));
                          _pickTime(_times.length - 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.3),
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('Add time',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Days of week
                  Text('Days',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final active = _days[i];
                      return GestureDetector(
                        onTap: () => setState(() => _days[i] = !_days[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLabels[i],
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.onPrimary
                                    : AppColors.onSurfaceVariant),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      if (hasSchedule)
                        TextButton(
                          onPressed: _delete,
                          child: Text('Remove',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error)),
                        ),
                      const Spacer(),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text(
                                  hasSchedule
                                      ? 'Update Reminders'
                                      : 'Set Reminders',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
