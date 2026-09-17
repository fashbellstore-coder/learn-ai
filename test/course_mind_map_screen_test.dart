import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/features/learn/mind_map_screen.dart';
import 'package:learn_ai/shared/models/content_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('course map expands from course to lesson', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const lesson = Lesson(
      id: 'lesson_test',
      trackId: 'track_test',
      moduleId: 'module_test',
      title: 'A test lesson',
      subtitle: 'Lesson subtitle',
      readTimeMinutes: 8,
      xpReward: 20,
    );
    const module = LearningModule(
      id: 'module_test',
      trackId: 'track_test',
      title: 'Test module',
      description: 'Module description',
      lessons: [lesson],
    );
    const track = RoadmapTrack(
      id: 'track_test',
      levelNumber: 1,
      title: 'Test course',
      tagline: 'Course tagline',
      icon: 'code',
      colorHex: '#2979FF',
      description: 'Course description',
      keySkills: [],
      modules: [module],
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CourseMindMapScreen()),
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
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tracksProvider.overrideWithValue(const [track]),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 courses  ·  1 modules  ·  1 lessons'), findsOneWidget);
    expect(find.text('A test lesson'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('course-track_test')));
    await tester.pumpAndSettle();
    expect(find.text('Test module'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module-module_test')));
    await tester.pumpAndSettle();
    expect(find.text('A test lesson'), findsOneWidget);

    await tester.tap(find.text('A test lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson opened'), findsOneWidget);
  });
}
