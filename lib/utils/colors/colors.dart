import 'package:flutter/material.dart';

/// Modern Material 3 color system for the Animal Sounds app.
///
/// Nature-inspired palette designed to be warm, friendly, and engaging
/// for children while maintaining accessibility standards.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary – Warm, nature-themed green
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimaryContainer = Color(0xFF1B5E20);

  // ---------------------------------------------------------------------------
  // Secondary – Playful orange accent
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFCC80);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color onSecondaryContainer = Color(0xFFE65100);

  // ---------------------------------------------------------------------------
  // Tertiary – Sky blue freshness
  // ---------------------------------------------------------------------------
  static const Color tertiary = Color(0xFF03A9F4);
  static const Color tertiaryLight = Color(0xFF81D4FA);
  static const Color tertiaryDark = Color(0xFF0288D1);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB3E5FC);
  static const Color onTertiaryContainer = Color(0xFF01579B);

  // ---------------------------------------------------------------------------
  // Surface & background
  // ---------------------------------------------------------------------------
  static const Color surface = Color(0xFFFFFBF5);
  static const Color surfaceDim = Color(0xFFF5F0EA);
  static const Color surfaceBright = Color(0xFFFFFDF9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF8F0);
  static const Color surfaceContainer = Color(0xFFFFF3E8);
  static const Color surfaceContainerHigh = Color(0xFFF5EDE4);
  static const Color surfaceContainerHighest = Color(0xFFEDE6DD);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ---------------------------------------------------------------------------
  // Outline
  // ---------------------------------------------------------------------------
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // ---------------------------------------------------------------------------
  // Semantic colors
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFC8E6C9);

  static const Color error = Color(0xFFE53935);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color onErrorContainer = Color(0xFFB71C1C);

  static const Color warning = Color(0xFFFFC107);
  static const Color onWarning = Color(0xFF1C1B1F);
  static const Color warningContainer = Color(0xFFFFF8E1);

  static const Color info = Color(0xFF03A9F4);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFB3E5FC);

  // ---------------------------------------------------------------------------
  // Card color palette – soft pastels for animal cards
  // ---------------------------------------------------------------------------
  static const List<Color> cardColors = [
    Color(0xFFC8E6C9), // soft green
    Color(0xFFFFE0B2), // soft orange
    Color(0xFFB3E5FC), // soft blue
    Color(0xFFF8BBD0), // soft pink
    Color(0xFFFFF9C4), // soft yellow
    Color(0xFFD1C4E9), // soft purple
    Color(0xFFFFCCBC), // soft coral
    Color(0xFFB2DFDB), // soft teal
    Color(0xFFFFE082), // soft amber
    Color(0xFFC5CAE9), // soft indigo
  ];

  // ---------------------------------------------------------------------------
  // Legacy aliases – keep backward compatibility
  // ---------------------------------------------------------------------------
  static const Color bottomNavigationBarButtonColor =
      Color.fromARGB(255, 110, 112, 95);
  static const Color iconColor = Color.fromARGB(255, 238, 217, 188);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Warm nature-themed gradient for card backgrounds.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  /// Playful sunset gradient for highlighted elements.
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  /// Sky gradient for background accents.
  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [tertiaryLight, tertiary],
  );

  /// Subtle surface gradient for page backgrounds.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceBright, surfaceDim],
  );

  /// Warm card gradient.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E1),
      Color(0xFFC8E6C9),
    ],
  );

  // ---------------------------------------------------------------------------
  // Material 3 ColorScheme
  // ---------------------------------------------------------------------------

  /// Full Material 3 [ColorScheme] assembled from the palette above.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceContainerHighest: surfaceContainerHighest,
  );
}

// Legacy top-level constants for files that still import them directly.
const MaterialColor themeColor = Colors.amber;
const Color bottomNavigationBarButtonColor =
    AppColors.bottomNavigationBarButtonColor;
const Color iconColor = AppColors.iconColor;
