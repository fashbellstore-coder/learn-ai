// LEGACY BACKUP — see README.md in this folder. Not imported anywhere.
// This is the "Terminal Noir" palette that shipped before the Nebula redesign.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const cyberCyan = Color(0xFF00F0FF);
  static const auroraGold = Color(0xFFF4B942);
  static const neonEmerald = Color(0xFF00E676);
  static const solarAmber = Color(0xFFFFAB00);
  static const cyberPink = Color(0xFFFF3D71);
  static const neuralBlue = Color(0xFF2979FF);

  static const deepSpace = Color(0xFF0A0E1A);
  static const surfaceCard = Color(0xFF131B2E);
  static const surfaceElevated = Color(0xFF1C2742);
  static const surfaceBorder = Color(0xFF263554);
  static const surfaceInput = Color(0xFF0E1524);
  static const codeBackground = Color(0xFF080C16);
  static const terminalGreen = Color(0xFF4AF626);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const lightCanvas = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFE2E8F0);
  static const lightBorder = Color(0xFF64748B);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF334155);
  static const lightTextMuted = Color(0xFF475569);
  static const lightCode = Color(0xFF0F172A);
  static const lightOnCode = Color(0xFFE2E8F0);
  static const lightCodeAccent = Color(0xFF4ADE80);
  static const lightAccent = Color(0xFF1D4ED8);
  static const lightInfo = Color(0xFF0F766E);
  static const lightGold = Color(0xFFC2410C);
  static const lightSuccess = Color(0xFF15803D);
  static const lightWarning = Color(0xFFB45309);
  static const lightDanger = Color(0xFFBE123C);
}

class AppPalette {
  const AppPalette({
    required this.canvas,
    required this.card,
    required this.elevated,
    required this.border,
    required this.input,
    required this.code,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.onCode,
    required this.codeAccent,
    required this.success,
    required this.warning,
    required this.info,
    required this.violet,
    required this.danger,
  });

  final Color canvas;
  final Color card;
  final Color elevated;
  final Color border;
  final Color input;
  final Color code;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color onCode;
  final Color codeAccent;
  final Color success;
  final Color warning;
  final Color info;
  final Color violet;
  final Color danger;

  static const dark = AppPalette(
    canvas: AppColors.deepSpace,
    card: AppColors.surfaceCard,
    elevated: AppColors.surfaceElevated,
    border: AppColors.surfaceBorder,
    input: AppColors.surfaceInput,
    code: AppColors.codeBackground,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    accent: AppColors.cyberCyan,
    onAccent: AppColors.deepSpace,
    onCode: AppColors.textPrimary,
    codeAccent: AppColors.terminalGreen,
    success: AppColors.neonEmerald,
    warning: AppColors.solarAmber,
    info: AppColors.cyberCyan,
    violet: AppColors.auroraGold,
    danger: AppColors.cyberPink,
  );

  static const light = AppPalette(
    canvas: AppColors.lightCanvas,
    card: AppColors.lightSurface,
    elevated: AppColors.lightElevated,
    border: AppColors.lightBorder,
    input: Color(0xFFE2E8F0),
    code: AppColors.lightCode,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    accent: AppColors.lightAccent,
    onAccent: Colors.white,
    onCode: AppColors.lightOnCode,
    codeAccent: AppColors.lightCodeAccent,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    info: AppColors.lightInfo,
    violet: AppColors.lightGold,
    danger: AppColors.lightDanger,
  );
}
