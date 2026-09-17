import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/routing/app_router.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/features/home/home_screen.dart';
import 'package:learn_ai/features/lessons/lesson_screen.dart';
import 'package:learn_ai/shared/models/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> mountHome(
  WidgetTester tester, {
  bool dark = true,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  addTearDown(router.dispose);
  router.go('/home');
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
  await tester.pumpAndSettle();
  return container;
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new learners see live library counts and can start immediately',
    (tester) async {
      final container = await mountHome(tester);
      final tracks = container.read(tracksProvider);
      final lessons = tracks.expand((t) => t.lessons).length;
      expect(find.text('${tracks.length}'), findsWidgets);
      expect(
        find.text(
          lessons.toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (_) => ',',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Courses'), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Courses')).dy, lessThan(700));
      expect(find.text('Welcome to Learn AI'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Start learning')).dy,
        lessThan(780),
      );
      await container
          .read(userControllerProvider.notifier)
          .setGoal(CareerGoal.llmEngineer);
      await tester.pumpAndSettle();
      expect(find.text('Learn AI, one step at a time.'), findsOneWidget);
      await reveal(tester, find.text('Start learning'));
      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);
    },
  );

  testWidgets(
    'home catalog link selects all courses, including after Learn was visited',
    (tester) async {
      final container = await mountHome(tester);
      final router = container.read(routerProvider);
      router.go('/learn');
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/learn?view=all',
      );
      final chip = find.widgetWithText(
        ChoiceChip,
        'All courses · ${container.read(tracksProvider).length}',
      );
      await reveal(tester, chip);
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    },
  );

  testWidgets(
    'returning learners resume the next unfinished lesson before discovery',
    (tester) async {
      final container = await mountHome(tester);
      final track = container
          .read(tracksProvider)
          .firstWhere((t) => t.id == 'track_python');
      await container
          .read(userControllerProvider.notifier)
          .completeLesson(track.lessons.first.id, 30, 10);
      await tester.pumpAndSettle();
      expect(find.text('Resume lesson'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Resume lesson')).dy,
        lessThan(
          tester.getTopLeft(find.text('Learn AI, one step at a time.')).dy,
        ),
      );
      await tester.tap(find.text('Resume lesson'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId,
        track.lessons[1].id,
      );
    },
  );

  for (final dark in [true, false]) {
    testWidgets(
      'discovery stays readable with large text on a small phone, dark=$dark',
      (tester) async {
        await mountHome(tester, dark: dark, width: 320, scale: 1.5);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await reveal(tester, find.text('Start learning'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
