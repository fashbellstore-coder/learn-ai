import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);
  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: palette.violet,
      onSecondary: Colors.white,
      tertiary: palette.success,
      onTertiary: isDark ? AppColors.deepSpace : Colors.white,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.card,
      onSurface: palette.textPrimary,
      outline: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.canvas,
      textTheme: AppTypography.textTheme(palette),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.canvas,
        foregroundColor: palette.textPrimary,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme(palette).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.input,
        hintStyle: AppTypography.textTheme(palette).bodyMedium?.copyWith(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      chipTheme: ChipThemeData(
        backgroundColor: palette.elevated,
        selectedColor: palette.accent.withValues(alpha: isDark ? 0.22 : 0.16),
        labelStyle: AppTypography.textTheme(palette).labelLarge,
        secondaryLabelStyle: AppTypography.textTheme(palette).labelLarge,
        side: BorderSide(color: palette.border),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.elevated,
        indicatorColor: palette.accent.withValues(alpha: isDark ? 0.18 : 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? palette.accent : palette.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.textTheme(palette).labelSmall?.copyWith(
                color: selected ? palette.accent : palette.textSecondary,
                fontWeight: FontWeight.w600,
              );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.elevated,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? palette.accent : palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? palette.accent.withValues(alpha: 0.4)
              : palette.elevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? palette.accent : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(palette.onAccent),
        side: BorderSide(color: palette.border, width: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.elevated,
        contentTextStyle: AppTypography.textTheme(palette).bodyMedium?.copyWith(
          color: palette.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
