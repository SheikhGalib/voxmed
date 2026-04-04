import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../providers/doctor_provider.dart';
import '../providers/hospital_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/voxmed_card.dart';

class FindCareScreen extends ConsumerStatefulWidget {
  const FindCareScreen({super.key});

  @override
  ConsumerState<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends ConsumerState<FindCareScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSpecialty = 'All Specialties';
  String? _selectedHospitalId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalSearchProvider(_searchQuery));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Care',
            style: GoogleFonts.manrope(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search hospitals and discover specialists with real-time availability.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          Text(
            'Hospitals',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          hospitalsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: VoxmedLoadingIndicator(message: 'Loading hospitals...'),
            ),
            error: (error, _) => SizedBox(
              height: 150,
              child: VoxmedErrorWidget(
                message: error.toString(),
                onRetry: () => ref.invalidate(hospitalSearchProvider(_searchQuery)),
              ),
            ),
            data: (hospitals) => _buildHospitalSection(hospitals),
          ),
          const SizedBox(height: 22),
          _buildDoctorsSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search hospital by name or city',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalSection(List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      return const SizedBox(
        height: 180,
        child: EmptyStateWidget(
          icon: Icons.local_hospital_outlined,
          title: 'No hospitals found',
          subtitle: 'Try a different search query.',
        ),
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hospitals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final hospital = hospitals[index];
          final isSelected = hospital.id == _selectedHospitalId;
          return SizedBox(
            width: 250,
            child: VoxmedCard(
              onTap: () {
                setState(() {
                  _selectedHospitalId = hospital.id;
                });
              },
              color: isSelected
                  ? AppColors.primaryContainer.withValues(alpha: 0.28)
                  : AppColors.surfaceContainerLow,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, color: AppColors.primary),
                      const Spacer(),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hospital.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hospital.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hospital.city}, ${hospital.country}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isSelected ? 'Selected' : 'Tap to view doctors',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorsSection() {
    final doctorsAsync = _selectedHospitalId != null
        ? ref.watch(doctorsByHospitalProvider(_selectedHospitalId!))
        : ref.watch(doctorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedHospitalId == null ? 'Doctors' : 'Doctors in Selected Hospital',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            _buildSpecialtyFilter(),
          ],
        ),
        const SizedBox(height: 12),
        doctorsAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: VoxmedLoadingIndicator(message: 'Loading doctors...'),
          ),
          error: (error, _) => SizedBox(
            height: 150,
            child: VoxmedErrorWidget(
              message: error.toString(),
              onRetry: () {
                if (_selectedHospitalId != null) {
                  ref.invalidate(doctorsByHospitalProvider(_selectedHospitalId!));
                } else {
                  ref.invalidate(doctorsProvider);
                }
              },
            ),
          ),
          data: (doctors) {
            final filteredDoctors = _selectedSpecialty == 'All Specialties'
                ? doctors
                : doctors.where((doctor) {
                    return doctor.specialty.toLowerCase() == _selectedSpecialty.toLowerCase();
                  }).toList();

            if (filteredDoctors.isEmpty) {
              return const SizedBox(
                height: 180,
                child: EmptyStateWidget(
                  icon: Icons.person_search,
                  title: 'No doctors available',
                  subtitle: 'Try another specialty or hospital.',
                ),
              );
            }

            return ListView.separated(
              itemCount: filteredDoctors.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doctor = filteredDoctors[index];
                return _DoctorTile(doctor: doctor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpecialtyFilter() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedSpecialty,
        borderRadius: BorderRadius.circular(12),
        items: const [
          DropdownMenuItem(value: 'All Specialties', child: Text('All Specialties')),
          DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology')),
          DropdownMenuItem(value: 'Neurology', child: Text('Neurology')),
          DropdownMenuItem(value: 'Dermatology', child: Text('Dermatology')),
          DropdownMenuItem(value: 'Pediatrics', child: Text('Pediatrics')),
          DropdownMenuItem(value: 'General Medicine', child: Text('General Medicine')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedSpecialty = value);
        },
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final Doctor doctor;

  const _DoctorTile({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return VoxmedCard(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceContainer,
                backgroundImage: (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty)
                    ? NetworkImage(doctor.avatarUrl!)
                    : null,
                child: (doctor.avatarUrl == null || doctor.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (doctor.hospitalName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospitalName!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                doctor.consultationFee == null
                    ? 'Fee N/A'
                    : '\$${doctor.consultationFee!.toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Text(
                doctor.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.work_outline, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                doctor.experienceYears == null
                    ? 'Experience N/A'
                    : '${doctor.experienceYears} years',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('${AppRoutes.doctorBooking}?doctorId=${doctor.id}'),
              child: const Text('Book Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}
