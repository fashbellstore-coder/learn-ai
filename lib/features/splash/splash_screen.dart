import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _go);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    final profile = ref.read(userProfileProvider);
    if (!profile.hasCompletedOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: palette.accent),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.accent.withValues(alpha: 0.22),
                    palette.violet.withValues(alpha: 0.12),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.08),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Text(
                'AI',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: palette.accent),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.tagline,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
