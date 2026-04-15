import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class VoxmedCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final VoidCallback? onTap;

  const VoxmedCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 24,
    this.padding,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ??
              Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.1),
                width: 1,
              ),
        ),
        child: child,
      ),
    );
  }
}
