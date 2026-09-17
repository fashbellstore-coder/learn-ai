import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/routing/app_router.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/data/repositories/user_repository.dart';
import 'package:learn_ai/features/auth/auth_screen.dart';
import 'package:learn_ai/features/home/home_screen.dart';
import 'package:learn_ai/features/onboarding/onboarding_screen.dart';
import 'package:learn_ai/shared/models/enums.dart';
import 'package:learn_ai/shared/models/user_models.dart';
import 'package:learn_ai/shared/widgets/app_primitives.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> launch(
  WidgetTester tester, {
  UserProfile profile = const UserProfile(),
  bool dark = true,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'learn_ai.user.v1': jsonEncode({
      'profile': profile.toJson(),
      'notes': [],
      'isDark': dark,
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'first launch asks one optional question and Explore first persists across launches',
    (tester) async {
      final container = await launch(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('What would you like to learn?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Show my path'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Explore first'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text('Explore library'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final restored = UserController(
        container.read(sharedPreferencesProvider),
      );
      addTearDown(restored.dispose);
      expect(restored.state.profile.hasCompletedOnboarding, isTrue);
      expect(restored.state.profile.isAuthenticated, isFalse);
      expect(restored.state.profile.goal, CareerGoal.aiEngineer);
      expect(restored.state.profile.hasSelectedPath, isFalse);
      container.read(routerProvider).go('/learn');
      await tester.pumpAndSettle();
      final count = container.read(tracksProvider).length;
      expect(find.text('My path · $count'), findsOneWidget);
      expect(find.text('All courses · $count'), findsOneWidget);
      expect(find.text('Build your AI future.'), findsNothing);
      expect(find.text('YOUR FIRST STEP'), findsNothing);
      await tester.tap(find.text('All courses · $count'));
      await tester.pumpAndSettle();
      expect(find.text('My path · $count'), findsOneWidget);
      container.read(routerProvider).go('/splash');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
    },
  );

  testWidgets(
    'selecting a focus goes straight to Home and saves the selected roadmap',
    (tester) async {
      final container = await launch(tester);
      await tester.tap(find.text('Explore first'));
      await tester.pumpAndSettle();
      expect(find.text('Explore library'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('AI agents & automation'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI agents & automation'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text('Show my path'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(CareerGoal.agentEngineer.subtitle), findsOneWidget);
      final restored = UserController(
        container.read(sharedPreferencesProvider),
      );
      addTearDown(restored.dispose);
      expect(restored.state.profile.goal, CareerGoal.agentEngineer);
      expect(restored.state.profile.hasSelectedPath, isTrue);
      container.read(routerProvider).go('/learn');
      await tester.pumpAndSettle();
      final p = restored.state.profile;
      final ids = container
          .read(roadmapGeneratorProvider)
          .generate(
            goal: p.goal,
            level: p.skillLevel,
            dailyMinutes: p.dailyGoalMinutes,
          );
      final count = container
          .read(tracksProvider)
          .where((t) => ids.contains(t.id))
          .length;
      expect(find.text('My path · $count'), findsOneWidget);
      expect(restored.state.profile.name, 'Learner');
      expect(restored.state.profile.dailyGoalMinutes, 20);
    },
  );

  testWidgets(
    'existing local learners bypass forms and retain their progress',
    (tester) async {
      final container = await launch(
        tester,
        profile: const UserProfile(
          name: 'Sam',
          hasCompletedOnboarding: true,
          isAuthenticated: false,
          xp: 180,
          completedLessonIds: {'py_01'},
          dailyGoalMinutes: 45,
        ),
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(container.read(userProfileProvider).xp, 180);
      expect(container.read(userProfileProvider).completedLessonIds, {'py_01'});
      expect(container.read(userProfileProvider).dailyGoalMinutes, 45);
    },
  );

  testWidgets(
    'optional profile details save without changing progress or requiring sign-in',
    (tester) async {
      final container = await launch(
        tester,
        profile: const UserProfile(hasCompletedOnboarding: true, xp: 180),
      );
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Sam');
      await tester.enterText(find.byType(TextField).last, 'sam@example.com');
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      final restored = UserController(
        container.read(sharedPreferencesProvider),
      );
      addTearDown(restored.dispose);
      expect(restored.state.profile.name, 'Sam');
      expect(restored.state.profile.email, 'sam@example.com');
      expect(restored.state.profile.xp, 180);
      expect(restored.state.profile.isAuthenticated, isFalse);
    },
  );

  for (final dark in [true, false]) {
    testWidgets('onboarding supports small phones and large text, dark=$dark', (
      tester,
    ) async {
      await launch(tester, dark: dark, width: 320, scale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('AI research'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Explore first'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Explore first').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Explore first'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text('Explore library'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }
}
