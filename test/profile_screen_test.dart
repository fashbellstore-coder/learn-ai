import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/routing/app_router.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/data/content/json_track_loader.dart';
import 'package:learn_ai/data/repositories/user_repository.dart';
import 'package:learn_ai/features/auth/auth_screen.dart';
import 'package:learn_ai/features/lessons/lesson_screen.dart';
import 'package:learn_ai/features/profile/profile_screens.dart';
import 'package:learn_ai/shared/models/content_models.dart';
import 'package:learn_ai/shared/models/user_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<LearningModule> modules;
  setUpAll(() async {
    modules = await const JsonTrackLoader(
      folder: 'python',
      trackId: 'track_python',
      moduleCount: 10,
      idPrefix: 'py',
    ).load();
  });
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    List<UserNote> notes = const [],
    double width = 390,
    double scale = 1,
    bool dark = true,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'learn_ai.user.v1': jsonEncode({
        'profile': profile.toJson(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'isDark': dark,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        trackModuleOverridesProvider.overrideWithValue({
          'track_python': modules,
        }),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/profile');
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
      250,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'profile exposes editing directly and does not promise unavailable rewards',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Milestones'));
      expect(find.text('Certificates'), findsNothing);
      expect(find.text('First Forward Pass'), findsNothing);
    },
  );

  testWidgets(
    'progress counts current content, milestones reflect completion, and today excludes old time',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await mount(
        tester,
        profile: UserProfile(
          name: 'Sam',
          completedLessonIds: {
            ...modules.expand((m) => m.lessons).map((l) => l.id),
            for (var i = 1; i <= 3; i++) 'track_python_interviews_$i',
            'removed_lesson',
          },
          completedProjectIds: {'proj_01', 'removed_project'},
          dailyMinutesSpent: 20,
          lastActiveDate: '2000-01-01',
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('50 Lessons completed')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('1 Courses completed')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('1 Projects completed')),
        findsOneWidget,
      );
      await reveal(tester, find.text('0 of 20 minutes'));
      expect(find.text('0 of 20 minutes'), findsOneWidget);
      await reveal(tester, find.text('Made it real'));
      for (final title in [
        'First step',
        'Finding your rhythm',
        'A course of your own',
        'Made it real',
      ]) {
        final status = tester.widget<Semantics>(
          find
              .ancestor(of: find.text(title), matching: find.byType(Semantics))
              .first,
        );
        expect(status.properties.label, 'Achieved');
      }
      semantics.dispose();
    },
  );

  testWidgets('saved notes open in full and link back to their lesson', (
    tester,
  ) async {
    final container = await mount(
      tester,
      notes: [
        const UserNote(
          id: 'note_1',
          lessonId: 'py_lesson_0_1',
          lessonTitle: 'Python introduction',
          content: 'My own explanation of Python.',
          timestamp: 'Just now',
        ),
      ],
    );
    await reveal(tester, find.text('Notes'));
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
    await tester.tap(find.text('Read note →'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.widgetWithText(SelectableText, 'My own explanation of Python.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open lesson'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId,
      'py_lesson_0_1',
    );
    expect(container.read(userControllerProvider).notes, hasLength(1));
  });

  for (final dark in [true, false]) {
    testWidgets(
      'Profile and Settings fit large text on small phones, dark=$dark',
      (tester) async {
        final container = await mount(
          tester,
          width: 320,
          scale: 1.5,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        await reveal(tester, find.text('Made it real'));
        expect(tester.takeException(), isNull);
        container.read(routerProvider).go('/settings');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await reveal(tester, find.byType(DropdownButtonFormField<int>));
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('30 min').last);
        await tester.pumpAndSettle();
        expect(container.read(userProfileProvider).dailyGoalMinutes, 30);
        final restored = UserController(
          container.read(sharedPreferencesProvider),
        );
        addTearDown(restored.dispose);
        expect(restored.state.profile.dailyGoalMinutes, 30);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
