import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/validators.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile != null) {
          _nameController.text = profile.fullName;
          _phoneController.text = profile.phone ?? '';
          _addressController.text = profile.address ?? '';
          _selectedGender = profile.gender;
          _selectedBloodGroup = profile.bloodGroup;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load profile');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final fileBytes = await File(picked.path).readAsBytes();
      final ext = picked.path.split('.').last;
      final filePath = '${user.id}/avatar.$ext';

      // Upload to storage
      await supabase.storage
          .from(Buckets.avatars)
          .uploadBinary(
            filePath,
            fileBytes,
            retryAttempts: 3,
          );

      // Get public URL
      final avatarUrl = supabase.storage
          .from(Buckets.avatars)
          .getPublicUrl(filePath);

      // Update profile
      final profileRepo = ref.read(profileRepositoryProvider);
      final updated = await profileRepo.updateProfile(
        user.id,
        {'avatar_url': avatarUrl},
      );

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isUploading = false;
      });
      showSuccessSnackBar(context, 'Profile photo updated!');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      showErrorSnackBar(context, 'Failed to upload photo: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim(),
      };
      if (_phoneController.text.trim().isNotEmpty) {
        updates['phone'] = _phoneController.text.trim();
      }
      if (_addressController.text.trim().isNotEmpty) {
        updates['address'] = _addressController.text.trim();
      }
      if (_selectedGender != null) {
        updates['gender'] = _selectedGender;
      }
      if (_selectedBloodGroup != null) {
        updates['blood_group'] = _selectedBloodGroup;
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      final updated = await profileRepo.updateProfile(user.id, updates);

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isSaving = false;
        _isEditing = false;
      });
      showSuccessSnackBar(context, 'Profile updated!');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showErrorSnackBar(context, 'Failed to save');
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to sign out');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Profile', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        actions: [
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                // Reset form
                if (_profile != null) {
                  _nameController.text = _profile!.fullName;
                  _phoneController.text = _profile!.phone ?? '';
                  _addressController.text = _profile!.address ?? '';
                  _selectedGender = _profile!.gender;
                  _selectedBloodGroup = _profile!.bloodGroup;
                }
                setState(() => _isEditing = false);
              },
              child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(Responsive.hPad(context), 8, Responsive.hPad(context), 40),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 28),
                  _buildUserInfoHeader(),
                  const SizedBox(height: 28),
                  if (_isEditing) _buildEditForm() else _buildInfoCards(),
                  const SizedBox(height: 32),
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.surfaceContainerHigh,
              backgroundImage: _profile?.avatarUrl != null
                  ? NetworkImage(_profile!.avatarUrl!)
                  : null,
              child: _profile?.avatarUrl == null
                  ? Text(
                      _getInitials(),
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Column(
      children: [
        Text(
          _profile?.fullName ?? 'User',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _profile?.email ?? '',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _profile?.role == UserRole.doctor
                ? AppColors.secondaryContainer
                : AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _profile?.role == UserRole.doctor
                    ? Icons.medical_services_outlined
                    : Icons.person_outline,
                size: 14,
                color: _profile?.role == UserRole.doctor
                    ? AppColors.onSecondaryContainer
                    : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _profile?.role == UserRole.doctor ? 'Doctor' : 'Patient',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _profile?.role == UserRole.doctor
                      ? AppColors.onSecondaryContainer
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.person_outline,
          title: 'Personal Information',
          items: [
            _InfoRow(label: 'Full Name', value: _profile?.fullName ?? '-'),
            _InfoRow(label: 'Gender', value: _profile?.gender?.capitalize() ?? 'Not set'),
            _InfoRow(label: 'Blood Group', value: _profile?.bloodGroup ?? 'Not set'),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.contact_phone_outlined,
          title: 'Contact Information',
          items: [
            _InfoRow(label: 'Email', value: _profile?.email ?? '-'),
            _InfoRow(label: 'Phone', value: _profile?.phone ?? 'Not set'),
            _InfoRow(label: 'Address', value: _profile?.address ?? 'Not set'),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            validator: Validators.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Your full name',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel('Phone'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            validator: Validators.phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+880 1712 345 678',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel('Gender'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedGender,
            icon: Icons.wc_outlined,
            items: {'male': 'Male', 'female': 'Female', 'other': 'Other'},
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          const SizedBox(height: 20),

          _buildLabel('Blood Group'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedBloodGroup,
            icon: Icons.bloodtype_outlined,
            items: {'A+': 'A+', 'A-': 'A-', 'B+': 'B+', 'B-': 'B-', 'AB+': 'AB+', 'AB-': 'AB-', 'O+': 'O+', 'O-': 'O-'},
            onChanged: (v) => setState(() => _selectedBloodGroup = v),
          ),
          const SizedBox(height: 20),

          _buildLabel('Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Your address',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save Changes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _handleSignOut,
        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
        label: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required IconData icon,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text('Select', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
              items: items.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: GoogleFonts.inter(fontSize: 14)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final name = _profile?.fullName ?? 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// --- Helper Widgets ---

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> items;

  const _InfoCard({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: item == items.last ? 0 : 14),
            child: item,
          )),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// String extension used locally
extension _StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
