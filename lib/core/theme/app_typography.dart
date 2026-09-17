import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nebula: Space Grotesk for headings, IBM Plex Sans for body copy, IBM Plex
/// Mono for labels/code — all bundled as local variable-font assets (see
/// pubspec.yaml), so rendering never depends on network access at runtime.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(AppPalette palette) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 34,
        height: 1.15,
        letterSpacing: -0.8,
        color: palette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.5,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.25,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.3,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.35,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.55,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: palette.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.45,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.2,
        color: palette.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.3,
        letterSpacing: 1.1,
        color: palette.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w500,
        fontSize: 10,
        height: 1.3,
        letterSpacing: 1.0,
        color: palette.textSecondary,
      ),
    );
  }

  static TextStyle mono(
    Color color, {
    double size = 12,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'IBMPlexMono',
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.55,
    );
  }
}
