import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Material 3 typography for the Animal Sounds app.
///
/// Uses the Nunito font family — a rounded, child-friendly typeface that is
/// highly legible and feels warm and approachable.
class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Headings
  // ---------------------------------------------------------------------------

  static TextStyle get headingLarge => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headingMedium => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get headingSmall => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Material 3 TextTheme
  // ---------------------------------------------------------------------------

  /// Returns a complete [TextTheme] built on Nunito for use in [ThemeData].
  static TextTheme get textTheme => GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.nunito(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        titleLarge: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: label,
      );
}

// ---------------------------------------------------------------------------
// Legacy aliases – keep backward compatibility
// ---------------------------------------------------------------------------

class MyTextStyles {
  static TextStyle get myCustomTextStyle => AppTextStyles.bodyLarge.copyWith(
        fontSize: 20,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get titleTextStyle => AppTextStyles.headingMedium.copyWith(
        letterSpacing: 1,
      );

  static TextStyle get subtitleTextStyle => AppTextStyles.bodyLarge.copyWith(
        fontSize: 18,
        letterSpacing: 1,
        fontWeight: FontWeight.normal,
      );
}
