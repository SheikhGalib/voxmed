import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';

class MyPatientsScreen extends ConsumerStatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(currentDoctorProvider);
    return doctorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (doctor) {
        if (doctor == null) return const Scaffold(body: SizedBox.shrink());
        return _buildContent(doctor.id);
      },
    );
  }

  Widget _buildContent(String doctorId) {
    final patientsAsync = ref.watch(doctorPatientsProvider(doctorId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(patientsAsync.valueOrNull?.length ?? 0),
          _buildSearchBar(),
          Expanded(
            child: patientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load patients',
                        style: GoogleFonts.manrope(
                            fontSize: 15, color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(doctorPatientsProvider(doctorId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (patients) {
                final filtered = _search.isEmpty
                    ? patients
                    : patients.where((p) {
                        final name = (p['profiles']?['full_name'] as String? ?? '')
                            .toLowerCase();
                        return name.contains(_search.toLowerCase());
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 56,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 14),
                        Text(
                          _search.isEmpty
                              ? 'No patients yet'
                              : 'No matching patients',
                          style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant),
                        ),
                        if (_search.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Patients who book appointments with you\nwill appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(doctorPatientsProvider(doctorId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _PatientCard(patient: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patients',
                    style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
                if (count > 0)
                  Text('$count total',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search patients…',
          hintStyle:
              GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          prefixIcon:
              const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _search = ''),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final profile = patient['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Unknown Patient';
    final avatarUrl = profile?['avatar_url'] as String?;
    final bloodGroup = profile?['blood_group'] as String?;
    final gender = profile?['gender'] as String?;
    final dob = profile?['date_of_birth'] as String?;
    final lastVisit = patient['scheduled_start_at'] as String?;
    final patientId = patient['patient_id'] as String;

    String? age;
    if (dob != null) {
      try {
        final birthDate = DateTime.parse(dob);
        final now = DateTime.now();
        age =
            '${now.year - birthDate.year - (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day) ? 1 : 0)}y';
      } catch (_) {}
    }

    String? lastVisitStr;
    if (lastVisit != null) {
      try {
        lastVisitStr = DateFormat('d MMM yyyy').format(DateTime.parse(lastVisit).toLocal());
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.patientDetail}?patientId=$patientId'),
      child: Container(
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (age != null)
                        _Chip(label: age),
                      if (gender != null)
                        _Chip(
                            label: gender[0].toUpperCase() +
                                gender.substring(1)),
                      if (bloodGroup != null)
                        _Chip(label: bloodGroup, isBlood: true),
                    ],
                  ),
                  if (lastVisitStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Last visit: $lastVisitStr',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isBlood;

  const _Chip({required this.label, this.isBlood = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isBlood
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isBlood ? AppColors.error : AppColors.onSurfaceVariant)),
    );
  }
}
