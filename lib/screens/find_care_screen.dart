import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/voxmed_card.dart';

class FindCareScreen extends StatefulWidget {
  const FindCareScreen({super.key});

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  int _selectedChip = 0;
  final _specialties = ['All Specialties', 'Cardiology', 'Neurology', 'Dermatology'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find Care',
              style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text('Access world-class specialists and healthcare facilities tailored to your specific needs.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildChips(),
          const SizedBox(height: 24),
          _buildDoctorCard(
            name: 'Dr. Julian Thorne',
            subtitle: 'Expert in interventional cardiology with 15 years experience.',
            specialty: 'CARDIOLOGY',
            rating: '4.9',
            consults: '2.4k+',
            experience: 'Today',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDT-tVFn5_C6v_J1ggmOXpH0-GQ6p9tnH-2EGE6_dZhgRFSb3ZerekHhYAsyE0SqHbqRbT3PKMWPU8f1C7eBEY46_Kj6lzq2C4aG4HRh9YYAtE7lJ-Q7GskOP-2AoYyxyOqfxiryQOZ16NMUMtb6bRuSeP5HEky_fH0_QHsg8Ibj_9j63PdKqPJzhQZq0PETbueJeHAwqpoBVzQ68ib2Qu1tLVOwySS6pcZy5uxj8Cm-zOSDeoJZf9TEcjiHOslaz4K05wO7rV5Gdc',
          ),
          const SizedBox(height: 16),
          _buildDoctorCard(
            name: 'Dr. Sarah Chen',
            subtitle: 'Specializing in brain degeneration and cognitive health.',
            specialty: 'NEUROLOGY',
            rating: '4.8',
            consults: '1.9k+',
            experience: 'Tomorrow',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDT-tVFn5_C6v_J1ggmOXpH0-GQ6p9tnH-2EGE6_dZhgRFSb3ZerekHhYAsyE0SqHbqRbT3PKMWPU8f1C7eBEY46_Kj6lzq2C4aG4HRh9YYAtE7lJ-Q7GskOP-2AoYyxyOqfxiryQOZ16NMUMtb6bRuSeP5HEky_fH0_QHsg8Ibj_9j63PdKqPJzhQZq0PETbueJeHAwqpoBVzQ68ib2Qu1tLVOwySS6pcZy5uxj8Cm-zOSDeoJZf9TEcjiHOslaz4K05wO7rV5Gdc',
          ),
          const SizedBox(height: 28),
          _buildFeaturedFacility(),
          const SizedBox(height: 24),
          Text('Specialists for You',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 16),
          _buildSpecialistRow('Dr. Sam Lawrence', 'Dermatology', Icons.person),
          const SizedBox(height: 12),
          _buildSpecialistRow('Dr. Medical Pharma', 'Pharmacy', Icons.local_pharmacy),
          const SizedBox(height: 12),
          _buildSpecialistRow('Dr. Priya Nayak', 'Endocrinology', Icons.person),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              decoration: InputDecoration(
                hintText: 'Search doctors, hospitals, or symptoms...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_specialties.length, (i) {
          final isActive = _selectedChip == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedChip = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _specialties[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String subtitle,
    required String specialty,
    required String rating,
    required String consults,
    required String experience,
    required String imageUrl,
  }) {
    return VoxmedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(specialty,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.primaryDim)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceContainer,
                backgroundImage: NetworkImage(imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(icon: Icons.star, label: rating, color: AppColors.primary),
              const SizedBox(width: 16),
              _StatChip(icon: Icons.people, label: consults, color: AppColors.secondary),
              const SizedBox(width: 16),
              _StatChip(icon: Icons.schedule, label: experience, color: AppColors.tertiary),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Book Appointment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedFacility() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surfaceContainerLow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            color: AppColors.surfaceContainerHigh,
            child: Stack(
              children: [
                Center(child: Icon(Icons.local_hospital, size: 64, color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('PREMIER FACILITY',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Central Medical Pavilion',
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                Text('Equipped with the latest AI-driven diagnostic suites and 24/7 critical care units.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FacilityTag(icon: Icons.star, label: '4.9'),
                    const SizedBox(width: 8),
                    _FacilityTag(icon: Icons.local_hospital, label: 'Emergency Dept'),
                    const SizedBox(width: 8),
                    _FacilityTag(icon: Icons.access_time, label: 'Open'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistRow(String name, String specialty, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface)),
                Text(specialty, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _FacilityTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FacilityTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
