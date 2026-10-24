// Typography system matching Skilloka Web Platform (Outfit for Headings, Inter for Body)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Headings & Brand: Outfit (Modern geometric, clean, authoritative)
  static TextStyle _getHeadingStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    try {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Outfit',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
  }

  // Body, Labels, and UI: Inter (Clean, neutral, hyper-legible)
  static TextStyle _getBodyStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
  }

  // Display Styles (Outfit)
  static TextStyle displayLarge = _getHeadingStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static TextStyle displayMedium = _getHeadingStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  static TextStyle displaySmall = _getHeadingStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // Headline Styles (Outfit)
  static TextStyle headlineLarge = _getHeadingStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static TextStyle headlineMedium = _getHeadingStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.29,
  );

  static TextStyle headlineSmall = _getHeadingStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // Title Styles (Outfit)
  static TextStyle titleLarge = _getHeadingStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static TextStyle titleMedium = _getHeadingStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.1,
  );

  static TextStyle titleSmall = _getHeadingStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 0.1,
  );

  // Body Styles (Inter)
  static TextStyle bodyLarge = _getBodyStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.2,
  );

  static TextStyle bodyMedium = _getBodyStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.15,
  );

  static TextStyle bodySmall = _getBodyStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.2,
  );

  // Label Styles (Inter)
  static TextStyle labelLarge = _getBodyStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = _getBodyStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = _getBodyStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 0.3,
  );

  // Custom Styles for Skilloka
  static TextStyle priceTag = _getHeadingStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.30,
  );

  static TextStyle badge = _getBodyStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static TextStyle greeting = _getHeadingStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Generate TextTheme for Material 3
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
