import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/error_handler.dart';
import '../models/doctor.dart';
import '../models/doctor_schedule.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/voxmed_card.dart';

class DoctorBookingDetailScreen extends ConsumerStatefulWidget {
  final String? doctorId;

  const DoctorBookingDetailScreen({super.key, this.doctorId});

  @override
  ConsumerState<DoctorBookingDetailScreen> createState() => _DoctorBookingDetailScreenState();
}

class _DoctorBookingDetailScreenState extends ConsumerState<DoctorBookingDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = widget.doctorId;
    if (doctorId == null || doctorId.isEmpty) {
      return const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.person_off,
          title: 'Doctor not found',
          subtitle: 'Please choose a doctor again from Find Care.',
        ),
      );
    }

    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));
    final scheduleAsync = ref.watch(doctorScheduleProvider(doctorId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Book Appointment',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: doctorAsync.when(
        loading: () => const VoxmedLoadingIndicator(message: 'Loading doctor details...'),
        error: (error, _) => VoxmedErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(doctorDetailProvider(doctorId)),
        ),
        data: (doctor) {
          return scheduleAsync.when(
            loading: () => const VoxmedLoadingIndicator(message: 'Loading available slots...'),
            error: (error, _) => VoxmedErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(doctorScheduleProvider(doctorId)),
            ),
            data: (schedules) {
              final slots = _buildSlotsForDate(_selectedDate, schedules);
              return _buildContent(doctor, schedules, slots);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(Doctor doctor, List<DoctorSchedule> schedules, List<DateTime> slots) {
    final appointmentState = ref.watch(appointmentProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorCard(doctor),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                if (schedules.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.schedule,
                    title: 'No schedule slots available',
                    subtitle: 'This doctor has not published available slots yet.',
                  )
                else if (slots.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'No slots for selected date',
                    subtitle: 'Try another date to see available times.',
                  )
                else
                  _buildSlots(slots),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for visit (optional)',
                    hintText: 'Briefly describe your concern',
                  ),
                ),
                if (appointmentState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    appointmentState.error!.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildBottomBar(doctor, appointmentState.isLoading, schedules.isNotEmpty && slots.isNotEmpty),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.surfaceContainer,
            backgroundImage: (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty)
                ? NetworkImage(doctor.avatarUrl!)
                : null,
            child: (doctor.avatarUrl == null || doctor.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 32, color: AppColors.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                if (doctor.hospitalName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doctor.hospitalName!,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  doctor.consultationFee == null
                      ? 'Consultation fee unavailable'
                      : 'Consultation fee: \$${doctor.consultationFee!.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final days = List.generate(7, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = DateUtils.isSameDay(day, _selectedDate);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    _selectedSlot = null;
                  });
                },
                child: Container(
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(day).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d').format(day),
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlots(List<DateTime> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return ChoiceChip(
              selected: isSelected,
              label: Text(DateFormat('hh:mm a').format(slot)),
              onSelected: (_) => setState(() => _selectedSlot = slot),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Doctor doctor, bool isSubmitting, bool hasSchedule) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting || !hasSchedule || _selectedSlot == null
              ? null
              : () => _confirmBooking(doctor),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Appointment'),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(Doctor doctor) async {
    final selectedSlot = _selectedSlot;
    if (selectedSlot == null) return;

    final startAt = selectedSlot;
    final endAt = selectedSlot.add(const Duration(minutes: 30));

    final created = await ref.read(appointmentProvider.notifier).createAppointment(
          doctorId: doctor.id,
          hospitalId: doctor.hospitalId,
          startAt: startAt,
          endAt: endAt,
          type: AppointmentType.inPerson,
          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        );

    if (!mounted) return;

    if (created == null) {
      final errorMessage = ref.read(appointmentProvider).error?.message ??
          'Unable to complete booking. Please try again.';
      showErrorSnackBar(context, errorMessage);
      return;
    }

    showSuccessSnackBar(context, 'Appointment booked successfully.');
    ref.invalidate(upcomingAppointmentsProvider);
    context.pop();
  }

  List<DateTime> _buildSlotsForDate(DateTime date, List<DoctorSchedule> schedules) {
    final weekday = date.weekday % 7;
    final daySchedules = schedules.where((s) => s.dayOfWeek == weekday && s.isActive).toList();
    if (daySchedules.isEmpty) return const [];

    final slots = <DateTime>[];
    for (final schedule in daySchedules) {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) {
        continue;
      }

      DateTime slot = DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(startParts[0]) ?? 0,
        int.tryParse(startParts[1]) ?? 0,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(endParts[0]) ?? 0,
        int.tryParse(endParts[1]) ?? 0,
      );

      while (slot.isBefore(end)) {
        if (slot.isAfter(DateTime.now())) {
          slots.add(slot);
        }
        slot = slot.add(Duration(minutes: schedule.slotDurationMinutes));
      }
    }

    return slots;
  }
}
