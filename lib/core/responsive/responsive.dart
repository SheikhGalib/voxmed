import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Breakpoints
// ─────────────────────────────────────────────
/// mobile < 600  |  tablet 600–1024  |  desktop ≥ 1024
class Responsive {
  Responsive._();

  static const double _mobileBreak = 600;
  static const double _tabletBreak = 1024;

  static double _w(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => _w(context) < _mobileBreak;
  static bool isTablet(BuildContext context) =>
      _w(context) >= _mobileBreak && _w(context) < _tabletBreak;
  static bool isDesktop(BuildContext context) => _w(context) >= _tabletBreak;

  /// Returns the value appropriate for the current breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // ── Padding ─────────────────────────────────
  /// Horizontal screen edge padding.
  static double hPad(BuildContext context) =>
      value(context, mobile: 20.0, tablet: 32.0, desktop: 48.0);

  /// Vertical section spacing.
  static double vPad(BuildContext context) =>
      value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

  // ── Font scale ──────────────────────────────
  /// Scale factor for typography.
  static double fontScale(BuildContext context) {
    final w = _w(context);
    if (w < 360) return 0.82;
    if (w < 480) return 0.92;
    if (w < 600) return 1.0;
    if (w < 900) return 1.08;
    return 1.15;
  }

  /// Scales a base font size clamped between 70 % and 140 % of base.
  static double fontSize(BuildContext context, double base) =>
      (base * fontScale(context)).clamp(base * 0.70, base * 1.40);

  // ── Layout ──────────────────────────────────
  /// Maximum content width (centres content on large screens).
  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 720.0, desktop: 960.0);

  /// Number of grid columns for card grids (hospitals, doctors, etc.)
  static int gridColumns(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 3);

  /// Card aspect-ratio for horizontal grids.
  static double cardAspectRatio(BuildContext context) =>
      value(context, mobile: 3.0, tablet: 3.2, desktop: 3.5);

  /// Fixed width for horizontal-scroll cards (hospital strip etc.)
  static double horizontalCardWidth(BuildContext context) =>
      value(context, mobile: (_w(context) * 0.70).clamp(180.0, 260.0),
          tablet: 280.0, desktop: 320.0);
}

// ─────────────────────────────────────────────
// Spacing system  (use instead of hard-coded px)
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────
// ResponsiveCard  (reusable layout card)
// ─────────────────────────────────────────────
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? 20.0;
    final p = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.value(context,
              mobile: AppSpacing.m, tablet: AppSpacing.l),
          vertical: AppSpacing.m,
        );
    Widget card = Container(
      width: double.infinity,
      padding: p,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(br),
      ),
      child: child,
    );
    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─────────────────────────────────────────────
// AdaptiveLayout  (mobile / tablet / desktop)
// ─────────────────────────────────────────────
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (Responsive.isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

// ─────────────────────────────────────────────
// CenteredContent  (constrains width on tablets)
// ─────────────────────────────────────────────
class CenteredContent extends StatelessWidget {
  final Widget child;

  const CenteredContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
