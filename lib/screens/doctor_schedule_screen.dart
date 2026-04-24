import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _weekStart {
    final d = _selectedDate;
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime get _monthStart =>
      DateTime(_selectedDate.year, _selectedDate.month, 1);
  DateTime get _monthEnd =>
      DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(currentDoctorProvider);
    return doctorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (doctor) {
        if (doctor == null) return const Scaffold(body: SizedBox.shrink());
        return _buildSchedule(doctor.id);
      },
    );
  }

  Widget _buildSchedule(String doctorId) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 13),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Day'),
              Tab(text: 'Week'),
              Tab(text: 'Month'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DayView(
                  doctorId: doctorId,
                  selectedDate: _selectedDate,
                  onDateChanged: (d) => setState(() => _selectedDate = d),
                ),
                _WeekView(
                  doctorId: doctorId,
                  weekStart: _weekStart,
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() {
                    _selectedDate = d;
                    _tabController.animateTo(0);
                  }),
                ),
                _MonthView(
                  doctorId: doctorId,
                  monthStart: _monthStart,
                  monthEnd: _monthEnd,
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() {
                    _selectedDate = d;
                    _tabController.animateTo(0);
                  }),
                  onMonthChanged: (d) => setState(() => _selectedDate = d),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule',
                    style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDate),
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            icon: const Icon(Icons.today_outlined, size: 20),
            tooltip: 'Today',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── DAY VIEW ───────────────────────

class _DayView extends ConsumerWidget {
  final String doctorId;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DayView({
    required this.doctorId,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.copyWith(hour: 23, minute: 59, second: 59);
    final apptAsync = ref.watch(
      doctorAppointmentsRangeProvider(
        (doctorId: doctorId, start: dayStart, end: dayEnd),
      ),
    );

    return Column(
      children: [
        _DateNavigator(
          date: selectedDate,
          onPrev: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          onNext: () => onDateChanged(selectedDate.add(const Duration(days: 1))),
        ),
        Expanded(
          child: apptAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (appointments) {
              if (appointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No appointments',
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
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _AppointmentCard(appointment: appointments[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── WEEK VIEW ───────────────────────

class _WeekView extends ConsumerWidget {
  final String doctorId;
  final DateTime weekStart;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekView({
    required this.doctorId,
    required this.weekStart,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    final apptAsync = ref.watch(
      doctorAppointmentsRangeProvider(
        (doctorId: doctorId, start: weekStart, end: weekEnd),
      ),
    );

    return apptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (appointments) {
        // Group by day-of-week
        final Map<int, List<Appointment>> byDay = {};
        for (final appt in appointments) {
          final dayIndex = appt.scheduledStartAt.toLocal().weekday - 1; // 0=Mon
          byDay.putIfAbsent(dayIndex, () => []).add(appt);
        }

        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, i) {
                  final day = weekStart.add(Duration(days: i));
                  final dayAppts = byDay[i] ?? [];
                  final isSelected =
                      day.year == selectedDate.year &&
                      day.month == selectedDate.month &&
                      day.day == selectedDate.day;
                  return GestureDetector(
                    onTap: () => onDateSelected(day),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(days[i],
                                    style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurface)),
                                Text(DateFormat('d').format(day),
                                    style: GoogleFonts.manrope(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurface)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: dayAppts.isEmpty
                                ? Text('No appointments',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant))
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: dayAppts.take(3).map((a) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(a.status)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          DateFormat('HH:mm')
                                              .format(a.scheduledStartAt.toLocal()),
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _statusColor(a.status)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${dayAppts.length}',
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
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
      },
    );
  }
}

// ─────────────────────── MONTH VIEW ───────────────────────

class _MonthView extends ConsumerWidget {
  final String doctorId;
  final DateTime monthStart;
  final DateTime monthEnd;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthView({
    required this.doctorId,
    required this.monthStart,
    required this.monthEnd,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(
      doctorAppointmentsRangeProvider(
        (doctorId: doctorId, start: monthStart, end: monthEnd),
      ),
    );

    return apptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (appointments) {
        // Count per day of month
        final Map<int, int> countByDay = {};
        for (final appt in appointments) {
          final d = appt.scheduledStartAt.toLocal().day;
          countByDay[d] = (countByDay[d] ?? 0) + 1;
        }

        final daysInMonth = monthEnd.day;
        final firstWeekday = monthStart.weekday; // 1=Mon

        return Column(
          children: [
            // Month navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => onMonthChanged(
                      DateTime(monthStart.year, monthStart.month - 1),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(monthStart),
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => onMonthChanged(
                      DateTime(monthStart.year, monthStart.month + 1),
                    ),
                  ),
                ],
              ),
            ),
            // Day-of-week headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.85,
                ),
                itemCount: daysInMonth + firstWeekday - 1,
                itemBuilder: (context, index) {
                  if (index < firstWeekday - 1) return const SizedBox.shrink();
                  final day = index - firstWeekday + 2;
                  final date = DateTime(monthStart.year, monthStart.month, day);
                  final count = countByDay[day] ?? 0;
                  final isSelected =
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final isToday = _isToday(date);

                  return GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (count > 0)
                            Container(
                              width: 16,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Summary
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _AppointmentCard(appointment: appointments[i], compact: true),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ─────────────────────── DATE NAVIGATOR ───────────────────────

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: AppColors.onSurface,
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('EEEE, MMM d').format(date),
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── APPOINTMENT CARD ───────────────────────

class _AppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  final bool compact;

  const _AppointmentCard({required this.appointment, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm').format(appointment.scheduledStartAt.toLocal());
    final endStr = DateFormat('HH:mm').format(appointment.scheduledEndAt.toLocal());
    final statusColor = _statusColor(appointment.status);

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person,
                size: compact ? 16 : 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName ?? 'Patient',
                  style: GoogleFonts.manrope(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface),
                ),
                Text(
                  '$timeStr – $endStr · ${_typeLabel(appointment.type)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                if (appointment.reason != null && !compact)
                  Text(
                    appointment.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(appointment.status),
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppointmentType t) {
    switch (t) {
      case AppointmentType.inPerson:
        return 'In-person';
      case AppointmentType.video:
        return 'Video';
      case AppointmentType.followUp:
        return 'Follow-up';
    }
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.confirmed:
    case AppointmentStatus.inProgress:
      return const Color(0xFF1B6D24);
    case AppointmentStatus.completed:
      return const Color(0xFF0D6EFD);
    case AppointmentStatus.cancelled:
    case AppointmentStatus.noShow:
      return const Color(0xFF9E422C);
    default:
      return const Color(0xFF5A6061);
  }
}
