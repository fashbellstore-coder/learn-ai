import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/asset_curriculum_loader.dart';
import 'package:learn_ai/core/utils/learning_math.dart';
import 'package:learn_ai/data/content/learning_paths.dart';
import 'package:learn_ai/data/repositories/curriculum_repository.dart';
import 'package:learn_ai/features/labs/experiment_screen.dart';
import 'package:learn_ai/shared/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SeedCurriculumRepository repo;
  setUpAll(() async {
    repo = SeedCurriculumRepository(
      trackOverrides: await const AssetCurriculumLoader().load(),
    );
  });
  final catalog = SeedCatalogRepository();
  test('career tracks, prerequisite graph and project references resolve', () {
    final courses = repo.getTracks();
    final ids = courses.map((c) => c.id).toSet();
    expect(ids.length, courses.length);
    expect(courses.length, 40);
    for (final path in learningPaths) {
      expect(path.courseIds.toSet().length, path.courseIds.length);
      expect(ids.containsAll(path.courseIds), isTrue, reason: path.title);
    }
    for (final course in courses) {
      expect(
        ids.containsAll(course.prerequisiteTrackIds),
        isTrue,
        reason: course.id,
      );
      for (final module in course.modules) {
        for (final lesson in module.lessons) {
          expect(lesson.trackId, course.id);
          // Existing legacy modules move lessons; new specialist IDs are exact.
          if (course.levelNumber >= 40) {
            expect(lesson.moduleId, module.id);
            for (final project in lesson.relatedProjectIds) {
              expect(catalog.project(project), isNotNull);
            }
          }
        }
      }
    }
    final graphIds = repo.skillGraph.map((n) => n.id).toSet();
    for (final node in repo.skillGraph) {
      expect(graphIds.containsAll(node.dependsOn), isTrue);
    }
    expect(catalog.projects.length, 21);
    expect(catalog.project('portfolio_platform')?.tier, ProjectTier.expert);
  });
  test(
    'short daily goals keep destination courses; LLM track does not require CV',
    () {
      const generator = RoadmapGenerator();
      final short = generator.generate(
        goal: CareerGoal.llmEngineer,
        level: SkillLevel.beginner,
        dailyMinutes: 10,
      );
      final long = generator.generate(
        goal: CareerGoal.llmEngineer,
        level: SkillLevel.beginner,
        dailyMinutes: 60,
      );
      expect(short, long);
      expect(short, contains('track_llm_architecture'));
      expect(short, contains('track_multimodal'));
      expect(short, isNot(contains('track_cv')));
    },
  );
  test('attention is normalized, symmetric and stable at extreme inputs', () {
    expect(attentionWeights(0, 1), everyElement(closeTo(1 / 3, 1e-12)));
    final positive = attentionWeights(4, 0.2);
    final negative = attentionWeights(-4, 0.2);
    expect(positive.reduce((a, b) => a + b), closeTo(1, 1e-12));
    expect(positive.first, closeTo(negative.last, 1e-12));
    expect(attentionWeights(1000, 0.2).last, 1);
  });
  test('memory separates model weights from context-dependent cache', () {
    const a = InferenceBudget(
      parametersB: 70,
      weightBytes: 2,
      context: 4096,
      concurrency: 1,
    );
    const b = InferenceBudget(
      parametersB: 70,
      weightBytes: 0.5,
      context: 8192,
      concurrency: 2,
    );
    expect(a.weightsGB, 140);
    expect(b.weightsGB, 35);
    expect(b.cacheGB, closeTo(a.cacheGB * 4, 1e-12));
    expect(a.cacheGB, closeTo(0.536870912, 1e-12));
  });
  for (final width in [360.0, 1024.0]) {
    testWidgets('lab controls update results at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: ExperimentScreen()));
      final query = tester.widget<Slider>(find.byType(Slider).first);
      query.onChanged!(0);
      await tester.pump();
      expect(find.text('Key 0: 33.3%'), findsOneWidget);
      await tester.ensureVisible(find.text('4-bit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4-bit'));
      await tester.pump();
      expect(find.textContaining('Weights: 3.50 GB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
