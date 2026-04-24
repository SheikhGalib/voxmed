import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/hospital_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Doctor-specific fields
  final _specialtyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _degreeController = TextEditingController();
  final _licenseController = TextEditingController();
  String? _selectedHospitalId;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialtyController.dispose();
    _departmentController.dispose();
    _degreeController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authResponse = await authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole.value,
      );

      if (_selectedRole == UserRole.doctor) {
        // authResponse.user is always present after signUp even if email confirmation
        // is required (session may be null, but the user object is not).
        final profileId = authResponse.user?.id;
        if (profileId == null) {
          throw AppException(
              message: 'Registration failed. Please try signing in to complete setup.');
        }

        await ref.read(doctorRepositoryProvider).createFullDoctorProfile(
              profileId: profileId,
              hospitalId: _selectedHospitalId!,
              specialty: _specialtyController.text.trim(),
              department: _departmentController.text.trim(),
              licenseNumber: _licenseController.text.trim(),
              qualifications: [_degreeController.text.trim()],
            );
      }

      if (!mounted) return;

      final message = _selectedRole == UserRole.doctor
          ? 'Account created! Your profile is pending hospital approval.'
          : 'Account created successfully!';
      showSuccessSnackBar(context, message);

      if (_selectedRole == UserRole.doctor) {
        context.go(AppRoutes.clinicalDashboard);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: Responsive.hPad(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRoleSelector(),
              const SizedBox(height: 28),
              _buildForm(),
              const SizedBox(height: 28),
              _buildRegisterButton(),
              const SizedBox(height: 20),
              _buildLoginLink(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join VoxMed to access smart healthcare',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _RoleCard(
              icon: Icons.person_outline,
              label: 'Patient',
              description: 'Book appointments & track health',
              isSelected: _selectedRole == UserRole.patient,
              onTap: () => setState(() => _selectedRole = UserRole.patient),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _RoleCard(
              icon: Icons.medical_services_outlined,
              label: 'Doctor',
              description: 'Manage patients & schedules',
              isSelected: _selectedRole == UserRole.doctor,
              onTap: () => setState(() => _selectedRole = UserRole.doctor),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Name', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
            decoration: const InputDecoration(
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text('Email', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text('Password', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Confirm Password', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: _selectedRole == UserRole.doctor
                ? TextInputAction.next
                : TextInputAction.done,
            validator: (v) =>
                Validators.confirmPassword(v, _passwordController.text),
            onFieldSubmitted:
                _selectedRole == UserRole.doctor ? null : (_) => _handleRegister(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          if (_selectedRole == UserRole.doctor) ...[
            const SizedBox(height: 28),
            _buildDoctorSectionHeader(),
            const SizedBox(height: 16),
            _buildHospitalDropdown(),
            const SizedBox(height: 20),
            Text('Department', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _departmentController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (_selectedRole != UserRole.doctor) return null;
                if (v == null || v.trim().isEmpty) return 'Enter your department';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Cardiology',
                prefixIcon: Icon(Icons.business_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text('Specialty', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _specialtyController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (_selectedRole != UserRole.doctor) return null;
                if (v == null || v.trim().isEmpty) return 'Enter your specialty';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Interventional Cardiology',
                prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text('Degree / Qualification', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _degreeController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (_selectedRole != UserRole.doctor) return null;
                if (v == null || v.trim().isEmpty) return 'Enter your degree';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'MBBS, MD',
                prefixIcon: Icon(Icons.school_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text('Practice License Number', style: _labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _licenseController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              validator: (v) {
                if (_selectedRole != UserRole.doctor) return null;
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your license number';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'BMDC-12345',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            _buildApprovalNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.medical_services_outlined,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Professional Details',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalDropdown() {
    final hospitalsAsync = ref.watch(hospitalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hospital', style: _labelStyle),
        const SizedBox(height: 8),
        hospitalsAsync.when(
          loading: () => Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Could not load hospitals. Please try again.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.error),
            ),
          ),
          data: (hospitals) => FormField<String>(
            validator: (v) {
              if (_selectedRole != UserRole.doctor) return null;
              if (_selectedHospitalId == null) {
                return 'Please select a hospital';
              }
              return null;
            },
            builder: (fieldState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedHospitalId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select your hospital',
                    prefixIcon:
                        const Icon(Icons.local_hospital_outlined, size: 20),
                    errorText: fieldState.errorText,
                  ),
                  items: hospitals
                      .map((h) => DropdownMenuItem(
                            value: h.id,
                            child: Text(
                              h.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedHospitalId = value);
                    fieldState.didChange(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your profile will be submitted for hospital approval. '
              'You will appear to patients only after the hospital approves your account.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Create Account',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.onSurfaceVariant),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign In',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
