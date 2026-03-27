import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class VoxmedAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
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
                Text(
                  'VoxMed',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
      actions: [
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceContainer,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDT-tVFn5_C6v_J1ggmOXpH0-GQ6p9tnH-2EGE6_dZhgRFSb3ZerekHhYAsyE0SqHbqRbT3PKMWPU8f1C7eBEY46_Kj6lzq2C4aG4HRh9YYAtE7lJ-Q7GskOP-2AoYyxyOqfxiryQOZ16NMUMtb6bRuSeP5HEky_fH0_QHsg8Ibj_9j63PdKqPJzhQZq0PETbueJeHAwqpoBVzQ68ib2Qu1tLVOwySS6pcZy5uxj8Cm-zOSDeoJZf9TEcjiHOslaz4K05wO7rV5Gdc',
              ),
            ),
          ),
        ...?actions,
      ],
    );
  }
}
