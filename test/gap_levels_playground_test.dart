import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/appdev_complete.dart';
import 'package:learn_ai/data/content/cloud_complete.dart';
import 'package:learn_ai/data/content/enterprise_complete.dart';
import 'package:learn_ai/data/content/frameworks_gap.dart';
import 'package:learn_ai/data/content/modern_gap.dart';
import 'package:learn_ai/data/content/python_gap.dart';
import 'package:learn_ai/data/content/sql_complete.dart';
import 'package:learn_ai/data/content/swe_complete.dart';
import 'package:learn_ai/data/runtime/python_interpreter.dart';
import 'package:learn_ai/shared/models/content_models.dart';

void main() {
  void check(Map<String, List<Lesson>> courses) {
    const interp = PythonInterpreter();
    for (final lessons in courses.values) {
      for (final lesson in lessons) {
        expect(lesson.runnableExamples.length, greaterThanOrEqualTo(2), reason: lesson.id);
        for (final snippet in lesson.runnableExamples) {
          if (snippet.expectedOutput.isEmpty) continue;
          final result = interp.run(snippet.code);
          expect(result.ok, isTrue, reason: '${lesson.id}: ${result.stderr}\n${snippet.code}');
          expect(result.stdout.trim(), snippet.expectedOutput.trim(), reason: lesson.id);
        }
      }
    }
  }

  test('software engineering playgrounds match the interpreter', () {
    check(sweCompleteCourses());
  });

  test('SQL playgrounds match the interpreter', () {
    check(sqlCompleteCourses());
  });

  test('AI app development playgrounds match the interpreter', () {
    check(appdevCompleteCourses());
  });

  test('cloud playgrounds match the interpreter', () {
    check(cloudCompleteCourses());
  });

  test('enterprise playgrounds match the interpreter', () {
    check(enterpriseCompleteCourses());
  });

  test('Python gap playgrounds match the interpreter', () {
    check(pythonGapCourses());
  });

  test('framework gap playgrounds match the interpreter', () {
    check(frameworksGapCourses());
  });

  test('modern gap playgrounds match the interpreter', () {
    check(modernGapCourses());
  });
}
