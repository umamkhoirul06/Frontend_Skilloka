/// App color palette for Skilloka
/// Primary: Teal (vocational/growth theme)
/// Secondary: Warm Orange (energy/action)
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Teal/Emerald
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF042F2E);

  // Secondary Colors - Warm Orange
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFEA580C);
  static const Color secondaryContainer = Color(0xFFFFEDD5);
  static const Color onSecondaryContainer = Color(0xFF431407);

  // Category Colors
  static const Color categoryLas = Color(0xFFF97316); // Orange - Welding
  static const Color categoryIT = Color(0xFF3B82F6); // Blue - IT
  static const Color categoryOtomotif = Color(0xFFEF4444); // Red - Automotive
  static const Color categoryTataBusana = Color(0xFF8B5CF6); // Purple - Fashion
  static const Color categoryTataBoga = Color(0xFFEC4899); // Pink - Culinary
  static const Color categoryBahasa = Color(0xFF06B6D4); // Cyan - Language

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFE5E5E5);
  static const Color outlineVariant = Color(0xFFD4D4D4);

  // Text Colors
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF525252);
  static const Color textTertiary = Color(0xFF737373);
  static const Color textDisabled = Color(0xFFA3A3A3);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF171717);
  static const Color surfaceVariantDark = Color(0xFF262626);
  static const Color outlineDark = Color(0xFF404040);
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D9488),
      Color(0xFF0F766E),
    ],
  );
}
