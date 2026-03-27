import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class DoctorBookingDetailScreen extends StatefulWidget {
  const DoctorBookingDetailScreen({super.key});

  @override
  State<DoctorBookingDetailScreen> createState() => _DoctorBookingDetailScreenState();
}

class _DoctorBookingDetailScreenState extends State<DoctorBookingDetailScreen> {
  int _selectedDay = 0;
  int _selectedTime = 1;
  final _days = [
    {'day': 'MON', 'date': '22'},
    {'day': 'TUE', 'date': '23'},
    {'day': 'WED', 'date': '24'},
    {'day': 'THU', 'date': '25'},
  ];
  final _times = ['09:00 AM', '10:30 AM', '11:45 AM', '02:15 PM', '03:30 PM', '04:45 PM'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Doctor Details', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border, color: AppColors.onSurfaceVariant), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorHeader(),
                  const SizedBox(height: 20),
                  _buildSmartAssistant(),
                  const SizedBox(height: 24),
                  Text('Select Date & Time', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 16),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildTimeSlots(),
                  const SizedBox(height: 24),
                  Text('About Dr. Elena', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 10),
                  Text(
                    'Specializing in cardiovascular health with over a decade of experience in clinical cardiology and vascular surgery. Known for a patient-centric approach and utilizing the latest diagnostic technologies.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(Icons.person, size: 48, color: AppColors.onSurfaceVariant),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.onTertiaryContainer),
                    const SizedBox(width: 2),
                    Text('4.9',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onTertiaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Dr. Elena Rodriguez', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text('Senior Cardiologist • 12 yrs exp.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(label: 'PATIENTS', value: '2.4k+'),
              const SizedBox(width: 32),
              _InfoChip(label: 'REVIEWS', value: '850'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAssistant() {
    return VoxmedCard(
      color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
      border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('SMART ASSISTANT',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          Text('Autonomous Rescheduling', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Dr. Smith your previous choice is unavailable today. We\'ve optimized your schedule by matching you with Dr. Rodriguez for a similar slot.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_days.length, (i) {
        final isActive = _selectedDay == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: Container(
              margin: EdgeInsets.only(right: i < _days.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(_days[i]['day']!,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                          color: isActive ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(_days[i]['date']!,
                      style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : AppColors.onSurface)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_times.length, (i) {
        final isActive = _selectedTime == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? null : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
            ),
            child: Text(_times[i],
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.onSurfaceVariant)),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CONSULTATION FEE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
              Text('\$120.00', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Confirm Appointment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: AppColors.onPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ],
    );
  }
}
