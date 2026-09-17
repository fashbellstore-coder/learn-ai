import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme_extras.dart';

/// The soft, layered glow behind Nebula's dark screens — three blurred
/// color blobs over the deep-space base, matching design_inspire's mockups.
/// Renders nothing in light mode, so day theme stays clean.
class NebulaBackdrop extends StatelessWidget {
  const NebulaBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.isDark) return const SizedBox.shrink();
    final palette = context.palette;
    return ColoredBox(
      color: palette.canvas,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Stack(
            children: [
              _blob(alignment: const Alignment(-0.76, -0.88), color: palette.accent),
              _blob(alignment: const Alignment(0.84, -0.64), color: palette.info),
              _blob(alignment: const Alignment(-0.4, 0.92), color: palette.violet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 340,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
