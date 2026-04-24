import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class VoxmedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showAvatar;

  const VoxmedAppBar({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.showAvatar = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: title != null
          ? Text(title!)
          : Row(
              children: [
                Icon(Icons.medical_information_outlined,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'VoxMed',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
      actions: [
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceContainer,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          _getInitials(profile?.fullName),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                loading: () => CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceContainer,
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                error: (_, _) => CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceContainer,
                  child: const Icon(Icons.person, size: 20, color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ...?actions,
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
