import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/features/learn/learn_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [360.0, 1024.0]) {
    for (final dark in [true, false]) {
      testWidgets('Learn layout and navigation at $width, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: LearnScreen()),
            ),
            GoRoute(
              path: '/lesson/:id',
              builder: (_, _) => const Scaffold(body: Text('Lesson opened')),
            ),
            GoRoute(
              path: '/course/:id',
              builder: (_, _) => const Scaffold(body: Text('Course opened')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp.router(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Build your AI future.'), findsNothing);
        expect(find.text('Your learning library'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byType(ChoiceChip).last);
        await tester.tap(find.byType(ChoiceChip).last);
        await tester.pumpAndSettle();
        expect(
          tester.widget<ChoiceChip>(find.byType(ChoiceChip).last).selected,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Python').first);
        await tester.pumpAndSettle();
        expect(find.text('Course opened'), findsOneWidget);
      });
    }
  }
}
