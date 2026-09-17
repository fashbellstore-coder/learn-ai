import 'package:flutter/material.dart';

import 'app_colors.dart';

extension LearnThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
