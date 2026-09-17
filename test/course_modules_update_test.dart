import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/asset_curriculum_loader.dart';
import 'package:learn_ai/data/content/json_track_loader.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:learn_ai/data/repositories/curriculum_repository.dart';
import 'package:learn_ai/data/repositories/interview_prep_repository.dart';
import 'package:learn_ai/shared/models/interview_models.dart';

void verifyCatalog(SeedCurriculumRepository repo) {
  final courses = repo.getTracks();
  expect(courses.take(3).map((c) => c.id), [
    'track_python',
    'track_math',
    'track_sql',
  ]);
  expect(repo.getTrack('track_sql')!.levelNumber, 2);
  expect(repo.getTrack('track_sql')!.prerequisiteTrackIds, ['track_math']);
  expect(courses.map((c) => c.levelNumber).toSet().length, courses.length);
  final ids = repo.allLessons.map((l) => l.id).toList();
  expect(ids.toSet().length, ids.length);
  for (final course in courses) {
    expect(
      course.modules.any((m) => m.title == 'Interview Questions'),
      isFalse,
    );
    expect(
      course.lessons.any((l) => l.moduleId.endsWith('_interviews')),
      isFalse,
    );
  }
  expect(
    repo.getTrack('track_prompt_engineering')!.modules.length,
    greaterThanOrEqualTo(2),
  );
  expect(
    repo
        .getTrack('track_genai')!
        .modules
        .any((m) => m.title.contains('Prompting')),
    isFalse,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'specialist courses load eight substantive modules and expanded prep',
    () async {
      final overrides = await const AssetCurriculumLoader().load();
      final prep = InterviewPrepRepository();
      const folders = [
        'pytorch',
        'llm_architecture',
        'distributed',
        'multimodal',
        'advanced_agents',
        'system_design',
        'graphrag',
        'ai_security',
        'reasoning',
        'advanced_math',
        'ai_coding',
        'research',
        'prompt_engineering',
      ];
      final newLessonIds = <String>{};
      for (final folder in folders) {
        final modules = overrides['track_$folder']!;
        expect(modules.length, 8, reason: folder);
        final lessons = modules.expand((m) => m.lessons).toList();
        expect(lessons.length, folder == 'prompt_engineering' ? 32 : 30);
        expect(modules.map((m) => m.title).toSet().length, 8);
        final added = modules.where((m) => m.id.contains('_depth_')).toList();
        expect(added.length, 6);
        for (final module in added) {
          expect(module.lessons.length, 4);
          for (final lesson in module.lessons) {
            expect(newLessonIds.add(lesson.id), isTrue);
            expect(lesson.sections.length, 3);
            expect(lesson.sections.map((s) => s.title), [
              'Concept',
              'Worked example',
              'Practice & verification',
            ]);
            expect(lesson.keyTakeaways, isNotEmpty);
            final question = lesson.quizQuestions.single;
            expect(question.options.where((o) => o.isCorrect).length, 1);
            expect(question.options.any((o) => !o.isCorrect), isTrue);
            expect(question.explanation, isNotEmpty);
          }
        }
        if (folder != 'prompt_engineering') {
          expect(modules.last.id, '${folder}_labs');
          expect(modules.last.lessons.map((l) => l.id), [
            '${folder}_lab_1',
            '${folder}_lab_2',
            '${folder}_lab_3',
          ]);
          expect(
            lessons.map((l) => l.id),
            containsAll([
              '${folder}_lesson_1',
              '${folder}_lesson_2',
              '${folder}_lesson_3',
            ]),
          );
        }
        final bank = await prep.load('track_$folder');
        final scenarios = bank
            .session(InterviewMode.scenario)
            .where((q) => q.id.contains('_depth_'))
            .toList();
        expect(scenarios.length, 6);
        for (final scenario in scenarios) {
          expect(scenario.followUpIds.length, 1);
          expect(bank.question(scenario.followUpIds.single).answer, isNotEmpty);
        }
      }
      expect(newLessonIds.length, 312);
    },
  );
  test(
    'all courses load learning modules from registered asset directories',
    () async {
      final overrides = await const AssetCurriculumLoader().load();
      final repo = SeedCurriculumRepository(trackOverrides: overrides);
      verifyCatalog(repo);
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/content/courses.json'),
      ) as Map<String, dynamic>;
      expect(overrides.length, 40);
      for (final entry in manifest['courses'] as List) {
        final folder = Directory('assets/content/${entry['folder']}');
        final files = folder.listSync().where(
          (f) => RegExp(r'module_\d+\.json$').hasMatch(f.path),
        );
        expect(files.length, entry['moduleCount']);
        expect(overrides[entry['trackId']]!.length, entry['moduleCount']);
        for (final module in overrides[entry['trackId']]!) {
          expect(module.lessons, isNotEmpty);
        }
      }
    },
  );
  test(
    'migrated content preserves lesson IDs, quizzes, labs and project links',
    () async {
      final overrides = await const AssetCurriculumLoader().load();
      final repo = SeedCurriculumRepository(trackOverrides: overrides);
      for (final id in [
        'genai_gen_prompt_engineering_basics',
        'genai_gen_few_shot_prompting',
        'llm_llme_system_prompt_policy',
        'prompt_contracts',
      ]) {
        final lesson = repo.getLesson(id)!;
        expect(lesson.trackId, 'track_prompt_engineering');
        expect(lesson.sections, isNotEmpty);
        expect(lesson.quizQuestions, isNotEmpty);
      }
      final lesson = repo.getLesson('pytorch_lesson_1')!;
      expect(lesson.xpReward, 40);
      expect(lesson.quizQuestions.single.id, 'pytorch_lesson_1_check');
      expect(lesson.quizQuestions.single.options.map((o) => o.id), [
        'true',
        'false',
      ]);
      expect(lesson.relatedProjectIds, ['portfolio_pytorch']);
      expect(repo.getLesson('pytorch_lab_1')!.miniProject, isNotNull);
      expect(repo.getLesson('gnp2_zero_01'), isNull);
      expect(overrides['track_prompt_engineering']!.first.id, 'genai_module_4');
    },
  );
  test('strict asset loading reports missing course content', () async {
    await expectLater(
      const JsonTrackLoader(
        folder: 'missing_course',
        trackId: 'missing',
        moduleCount: 1,
      ).load(strict: true),
      throwsFormatException,
    );
  });
}
