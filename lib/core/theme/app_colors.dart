import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1B6D24);
  static const Color primaryDim = Color(0xFF076019);
  static const Color primaryContainer = Color(0xFFA3F69C);
  static const Color onPrimary = Color(0xFFE5FFDD);
  static const Color onPrimaryContainer = Color(0xFF065F18);
  static const Color primaryFixed = Color(0xFFA3F69C);
  static const Color primaryFixedDim = Color(0xFF95E88F);
  static const Color onPrimaryFixed = Color(0xFF004B0F);
  static const Color onPrimaryFixedVariant = Color(0xFF176A21);
  static const Color inversePrimary = Color(0xFF9DF197);

  // Secondary
  static const Color secondary = Color(0xFF466370);
  static const Color secondaryDim = Color(0xFF3A5764);
  static const Color secondaryContainer = Color(0xFFC9E7F7);
  static const Color onSecondary = Color(0xFFF3FAFF);
  static const Color onSecondaryContainer = Color(0xFF395663);
  static const Color secondaryFixed = Color(0xFFC9E7F7);
  static const Color secondaryFixedDim = Color(0xFFBBD9E9);
  static const Color onSecondaryFixed = Color(0xFF264350);
  static const Color onSecondaryFixedVariant = Color(0xFF435F6D);

  // Tertiary
  static const Color tertiary = Color(0xFF4B6551);
  static const Color tertiaryDim = Color(0xFF3F5945);
  static const Color tertiaryContainer = Color(0xFFD7F6DB);
  static const Color onTertiary = Color(0xFFE8FFE9);
  static const Color onTertiaryContainer = Color(0xFF445E4A);
  static const Color tertiaryFixed = Color(0xFFD7F6DB);
  static const Color tertiaryFixedDim = Color(0xFFC9E7CD);
  static const Color onTertiaryFixed = Color(0xFF324C39);
  static const Color onTertiaryFixedVariant = Color(0xFF4E6954);

  // Error
  static const Color error = Color(0xFF9E422C);
  static const Color errorDim = Color(0xFF5C1202);
  static const Color errorContainer = Color(0xFFFE8B70);
  static const Color onError = Color(0xFFFFF7F6);
  static const Color onErrorContainer = Color(0xFF742410);

  // Surface
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFD4DBDD);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F4);
  static const Color surfaceContainer = Color(0xFFEBEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE4E9EA);
  static const Color surfaceContainerHighest = Color(0xFFDDE4E5);
  static const Color surfaceVariant = Color(0xFFDDE4E5);
  static const Color surfaceTint = Color(0xFF1B6D24);

  // On Surface
  static const Color onSurface = Color(0xFF2D3435);
  static const Color onSurfaceVariant = Color(0xFF5A6061);
  static const Color inverseSurface = Color(0xFF0C0F0F);
  static const Color inverseOnSurface = Color(0xFF9C9D9D);

  // Background
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF2D3435);

  // Outline
  static const Color outline = Color(0xFF757C7D);
  static const Color outlineVariant = Color(0xFFADB3B4);
}

/// Doctor-specific blue color palette (used in doctor-role screens only).
/// Patient screens continue to use the main green [AppColors].
class DoctorColors {
  DoctorColors._();

  static const Color primary       = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight  = Color(0xFF1E88E5); // Blue 600
  static const Color primaryDark   = Color(0xFF0D47A1); // Blue 900
  static const Color primaryContainer = Color(0xFFE3F2FD); // Blue 50
  static const Color onPrimary     = Color(0xFFFFFFFF);
  static const Color border        = Color(0xFFBBDEFB); // Blue 100
  static const Color lightBg       = Color(0xFFF5F9FF); // Very light blue
  static const Color cardBg        = Color(0xFFEEF4FF); // Light blue card
  static const Color accent        = Color(0xFF0288D1); // Light Blue 700
  static const Color accentLight   = Color(0xFF4FC3F7); // Light Blue 300
  static const Color statGreen     = Color(0xFF2E7D32); // for positive numbers
  static const Color statOrange    = Color(0xFFE65100); // for warnings
  static const Color navSelected   = Color(0xFF1565C0);
}
