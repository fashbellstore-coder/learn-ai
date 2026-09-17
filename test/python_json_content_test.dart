import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/json_track_loader.dart';
import 'package:learn_ai/data/content/practice_bank_loader.dart';
import 'package:learn_ai/data/repositories/curriculum_repository.dart';
import 'package:learn_ai/data/runtime/python_interpreter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('python JSON modules load as a complete 10-module course', () async {
    final modules = await const JsonTrackLoader(
      folder: 'python',
      trackId: 'track_python',
      moduleCount: 10,
      idPrefix: 'py',
    ).load();

    expect(modules, hasLength(10));
    expect(modules.first.id, 'py_module_0');
    expect(modules.first.title, contains('Fundamentals'));
    expect(modules.last.id, 'py_module_9');
    expect(modules.last.title, contains('Modules'));

    final lessons = modules.expand((m) => m.lessons).toList();
    expect(lessons, hasLength(50));
    expect(lessons.map((l) => l.id).toSet(), hasLength(50));

    for (final lesson in lessons) {
      expect(lesson.sections, isNotEmpty, reason: lesson.id);
      expect(
        lesson.quizQuestions.length,
        greaterThanOrEqualTo(3),
        reason: lesson.id,
      );
      expect(
        lesson.codingChallenge,
        isNotNull,
        reason: '${lesson.id} needs an exercise',
      );
      expect(
        lesson.quizQuestions.every(
          (q) => q.options.where((o) => o.isCorrect).length == 1,
        ),
        isTrue,
        reason: lesson.id,
      );
    }

    final first = lessons.first;
    expect(first.id, 'py_lesson_0_1');
    expect(first.title, 'What is Python?');
    expect(first.codingChallenge!.expectedOutput, 'Welcome to Python!');
  });

  test(
    'Python catalog contains learning lessons without interview-prep lessons',
    () async {
      final jsonModules = await const JsonTrackLoader(
        folder: 'python',
        trackId: 'track_python',
        moduleCount: 10,
        idPrefix: 'py',
      ).load();
      final repo = SeedCurriculumRepository(
        trackOverrides: {'track_python': jsonModules},
      );
      final python = repo.getTrack('track_python')!;

      expect(python.modules.first.id, 'py_module_0');
      expect(
        python.modules.where((m) => m.id.startsWith('py_module_')),
        hasLength(10),
      );
      expect(python.modules, hasLength(10));
      expect(
        python.modules.any((m) => m.title == 'Interview Questions'),
        isFalse,
      );
      expect(python.lessons, hasLength(50));
      expect(
        python.modules.take(10).map((m) => m.id),
        jsonModules.take(10).map((m) => m.id),
      );
      expect(
        python.modules
            .take(10)
            .expand((m) => m.lessons)
            .every((l) => l.id.startsWith('py_lesson_')),
        isTrue,
      );
      expect(
        repo.allLessons.where((l) => l.trackId == 'track_python'),
        hasLength(50),
      );
      expect(repo.getModule('track_python', 'course_py_numpy'), isNull);
      expect(repo.getModule('track_python', 'course_py_pandas'), isNull);
      expect(repo.getLesson('py_syntax_01'), isNull);
      expect(repo.getLesson('py_lesson_0_1')?.title, 'What is Python?');
    },
  );

  test('python practice bank loads drills and interview prompts', () async {
    final bank = await const PracticeBankLoader().load();
    expect(bank.drills, hasLength(204));
    expect(bank.interviews, isNotEmpty);
    expect(bank.drills.map((q) => q.id).toSet(), hasLength(204));
    expect(
      bank.drills.every((q) => q.options.where((o) => o.isCorrect).length == 1),
      isTrue,
    );
    expect(bank.drills.any((q) => q.topic.contains('Fundamentals')), isTrue);
  });

  test('first python JSON exercise runs in the in-app interpreter', () async {
    final modules = await const JsonTrackLoader(
      folder: 'python',
      trackId: 'track_python',
      moduleCount: 1,
      idPrefix: 'py',
    ).load();
    final lesson = modules.first.lessons.first;
    const interp = PythonInterpreter();
    final result = interp.run('print("Welcome to Python!")');
    expect(result.ok, isTrue);
    expect(result.stdout.trim(), lesson.codingChallenge!.expectedOutput.trim());
  });
}
