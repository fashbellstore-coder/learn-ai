import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/llmops_complete.dart';
import 'package:learn_ai/data/content/mlops_complete.dart';
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

  test('mlops complete playgrounds match the interpreter', () {
    check(mlopsCompleteCourses());
  });

  test('llmops complete playgrounds match the interpreter', () {
    check(llmopsCompleteCourses());
  });
}
