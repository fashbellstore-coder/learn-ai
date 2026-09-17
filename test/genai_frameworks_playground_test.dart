import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/genai_frameworks.dart';
import 'package:learn_ai/data/runtime/python_interpreter.dart';

void main() {
  test('genai framework playgrounds match the in-app interpreter', () {
    const interp = PythonInterpreter();
    for (final lessons in genaiFrameworkCourses().values) {
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
  });
}
