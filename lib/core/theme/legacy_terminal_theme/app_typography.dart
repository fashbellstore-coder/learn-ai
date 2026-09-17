// LEGACY BACKUP — see README.md in this folder. Not imported anywhere.
// This is the "Terminal Noir" typography (PlusJakartaSans + IBMPlexMono)
// that shipped before the Nebula redesign.

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(AppPalette palette) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 34,
        height: 1.15,
        letterSpacing: -0.8,
        color: palette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.5,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.25,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.3,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.35,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.55,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: palette.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.45,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
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
        color: palette.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.w500,
        fontSize: 10,
        height: 1.3,
        letterSpacing: 0.4,
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
