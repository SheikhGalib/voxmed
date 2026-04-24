import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../repositories/collaboration_repository.dart';

final _collabRepoProvider = Provider((_) => CollaborationRepository());

final peerDoctorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(_collabRepoProvider).listPeerDoctors();
});

class CollaborativeHubScreen extends ConsumerStatefulWidget {
  const CollaborativeHubScreen({super.key});

  @override
  ConsumerState<CollaborativeHubScreen> createState() => _CollaborativeHubScreenState();
}

class _CollaborativeHubScreenState extends ConsumerState<CollaborativeHubScreen> {
  String _search = '';
  String? _filterSpecialty;

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(peerDoctorsProvider);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: doctorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                const SizedBox(height: 12),
                Text(e.toString(), style: GoogleFonts.inter(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: () => ref.refresh(peerDoctorsProvider), child: const Text('Retry')),
              ]),
            ),
            data: (doctors) {
              final specialties = doctors.map((d) => d['specialty'] as String? ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();

              final filtered = doctors.where((d) {
                final name = (d['profiles']?['full_name'] as String? ?? '').toLowerCase();
                final spec = (d['specialty'] as String? ?? '').toLowerCase();
                final hosp = (d['hospitals']?['name'] as String? ?? '').toLowerCase();
                final q = _search.toLowerCase();
                final matchSearch = q.isEmpty || name.contains(q) || spec.contains(q) || hosp.contains(q);
                final matchSpec = _filterSpecialty == null || d['specialty'] == _filterSpecialty;
                return matchSearch && matchSpec;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text('No doctors found', style: GoogleFonts.manrope(fontSize: 15, color: AppColors.onSurfaceVariant)),
                );
              }

              return Column(
                children: [
                  if (specialties.isNotEmpty) _buildSpecialtyChips(specialties),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref.refresh(peerDoctorsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _DoctorTile(doctor: filtered[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search doctors by name, specialty, hospital...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
          suffixIcon: _search.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = ''))
              : null,
          filled: true,
          fillColor: DoctorColors.lightBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChips(List<String> specialties) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SpecialtyChip(label: 'All', selected: _filterSpecialty == null, onTap: () => setState(() => _filterSpecialty = null)),
          ...specialties.map((s) => _SpecialtyChip(
              label: s, selected: _filterSpecialty == s, onTap: () => setState(() => _filterSpecialty = _filterSpecialty == s ? null : s))),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SpecialtyChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? DoctorColors.primary : DoctorColors.lightBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? DoctorColors.primary : DoctorColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.onSurfaceVariant)),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorTile({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final profile = doctor['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Doctor';
    final avatarUrl = profile?['avatar_url'] as String?;
    final specialty = doctor['specialty'] as String? ?? '';
    final hospital = (doctor['hospitals'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final doctorId = doctor['id'] as String? ?? '';

    return InkWell(
      onTap: () {
        final encodedName = Uri.encodeComponent(name);
        final encodedSpec = Uri.encodeComponent(specialty);
        context.push('${AppRoutes.doctorChat}?doctorId=$doctorId&name=$encodedName&specialty=$encodedSpec');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DoctorColors.border, width: 1),
          boxShadow: [BoxShadow(color: DoctorColors.primary.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: DoctorColors.primaryContainer,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: DoctorColors.primary))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            if (specialty.isNotEmpty) Text(specialty, style: GoogleFonts.inter(fontSize: 12, color: DoctorColors.primary, fontWeight: FontWeight.w600)),
            if (hospital.isNotEmpty) Text(hospital, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ])),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: DoctorColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.chat_bubble_outline, size: 18, color: DoctorColors.primary),
          ),
        ]),
      ),
    );
  }
}
