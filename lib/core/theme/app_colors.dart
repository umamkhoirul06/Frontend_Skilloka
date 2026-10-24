// App color palette for Skilloka
// Primary: Royal Blue (matching Skilloka Web platform brand)
// Secondary: Amber Gold (matching Skilloka Web upskilling arrow)
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Skilloka Web Brand Blue
  static const Color primary = Color(0xFF2563EB); // brand-600
  static const Color primaryLight = Color(0xFF3B82F6); // brand-500
  static const Color primaryDark = Color(0xFF1D4ED8); // brand-700
  static const Color primaryContainer = Color(0xFFDBEAFE); // brand-100
  static const Color onPrimaryContainer = Color(0xFF1E3A8A); // brand-900

  // Secondary Colors - Skilloka Web Amber Gold
  static const Color secondary = Color(0xFFF59E0B); // amberbrand-500
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFD97706); // amberbrand-600
  static const Color secondaryContainer = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF78350F);

  // Deep Navy Brand Colors (Web background & headers)
  static const Color navy = Color(0xFF0F172A);
  static const Color navyLight = Color(0xFF1E293B);

  // Category Colors
  static const Color categoryLas = Color(0xFFF97316); // Orange - Welding
  static const Color categoryIT = Color(0xFF3B82F6); // Blue - IT
  static const Color categoryOtomotif = Color(0xFFEF4444); // Red - Automotive
  static const Color categoryTataBusana = Color(0xFF8B5CF6); // Purple - Fashion
  static const Color categoryTataBoga = Color(0xFFEC4899); // Pink - Culinary
  static const Color categoryBahasa = Color(0xFF06B6D4); // Cyan - Language

  // Neutral Colors (Matching Skilloka Web Slate System)
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // slate-100
  static const Color outline = Color(0xFFE2E8F0); // slate-200
  static const Color outlineVariant = Color(0xFFCBD5E1); // slate-300

  // Text Colors (Light Mode base values - Slate System)
  static const Color _textPrimaryLight = Color(0xFF0F172A); // slate-900
  static const Color _textSecondaryLight = Color(0xFF475569); // slate-600
  static const Color _textTertiaryLight = Color(0xFF94A3B8); // slate-400
  static const Color _textDisabledLight = Color(0xFFCBD5E1); // slate-300

  // Text Colors (Dark Mode base values)
  static const Color _textPrimaryDarkVal = Color(0xFFF8FAFC);
  static const Color _textSecondaryDarkVal = Color(0xFF94A3B8);
  static const Color _textTertiaryDarkVal = Color(0xFF64748B);
  static const Color _textDisabledDarkVal = Color(0xFF475569);

  // Legacy static accessors (light mode defaults, used by theme definitions)
  static const Color textPrimary = _textPrimaryLight;
  static const Color textSecondary = _textSecondaryLight;
  static const Color textTertiary = _textTertiaryLight;
  static const Color textDisabled = _textDisabledLight;

  // Adaptive color methods — use these in widgets for dark mode support
  static Color textPrimaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _textPrimaryDarkVal : _textPrimaryLight;

  static Color textSecondaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _textSecondaryDarkVal : _textSecondaryLight;

  static Color textTertiaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _textTertiaryDarkVal : _textTertiaryLight;

  static Color textDisabledFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _textDisabledDarkVal : _textDisabledLight;

  static Color surfaceVariantFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceVariantDark : surfaceVariant;

  // Semantic Colors
  static const Color success = Color(0xFF059669); // emerald-600
  static const Color successContainer = Color(0xFFECFDF5); // emerald-50
  static const Color verifiedBorder = Color(0xFFA7F3D0); // emerald-200
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color danger = Color(0xFFEF4444); // alias for error
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFEFF6FF);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0B132B);
  static const Color surfaceDark = Color(0xFF1E293B); // slate-800
  static const Color surfaceVariantDark = Color(0xFF334155); // slate-700
  static const Color outlineDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Gradient Definitions (Matching Skilloka Web)
  // Web: linear-gradient(135deg, #2563eb 0%, #4f46e5 100%)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB), // brand-600
      Color(0xFF4F46E5), // indigo-600
    ],
  );

  // Web: linear-gradient(135deg, #f97316 0%, #ea580c 100%)
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A), // slate-900
      Color(0xFF1E293B), // slate-800
    ],
  );
}
