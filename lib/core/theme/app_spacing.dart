import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusSm = 8.0;
  static const radiusMd = 14.0;
  static const radiusLg = 22.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  static const touchTarget = 48.0;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
  ];
}
