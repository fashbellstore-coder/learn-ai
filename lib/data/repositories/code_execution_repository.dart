import 'dart:convert';
import 'dart:io';

import '../../shared/models/enums.dart';
import '../runtime/python_interpreter.dart';

class ExecutionResult {
  const ExecutionResult({
    required this.isSuccess,
    required this.stdout,
    this.stderr = '',
    this.elapsedMs = 8,
  });

  final bool isSuccess;
  final String stdout;
  final String stderr;
  final int elapsedMs;
}

abstract class CodeExecutionRepository {
  ExecutionResult run(CodeLanguage language, String code);
}

/// Runs Python for real: host `python3` when present, otherwise the in-app interpreter.
class LocalCodeExecutionRepository implements CodeExecutionRepository {
  const LocalCodeExecutionRepository();

  @override
  ExecutionResult run(CodeLanguage language, String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const ExecutionResult(isSuccess: false, stdout: '', stderr: 'Nothing to run.');
    }
    if (language == CodeLanguage.json) {
      try {
        jsonDecode(trimmed);
        return const ExecutionResult(isSuccess: true, stdout: 'Valid JSON document');
      } catch (e) {
        return ExecutionResult(isSuccess: false, stdout: '', stderr: 'JSON parse error: $e');
      }
    }
    if (language != CodeLanguage.python) {
      return const ExecutionResult(
        isSuccess: false,
        stdout: '',
        stderr: 'This playground runs Python (and JSON). Switch the snippet to Python.',
      );
    }

    final native = _runHostPython(trimmed);
    if (native != null) return native;

    final started = DateTime.now();
    final result = const PythonInterpreter().run(trimmed);
    final ms = DateTime.now().difference(started).inMilliseconds;
    if (!result.ok) {
      return ExecutionResult(isSuccess: false, stdout: result.stdout, stderr: result.stderr, elapsedMs: ms);
    }
    return ExecutionResult(isSuccess: true, stdout: result.stdout, elapsedMs: ms);
  }

  ExecutionResult? _runHostPython(String code) {
    try {
      final proc = Process.runSync(
        'python3',
        ['-c', code],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final stdout = (proc.stdout as String).replaceAll(RegExp(r'\n$'), '');
      final stderr = (proc.stderr as String).trim();
      if (proc.exitCode == 0) {
        return ExecutionResult(isSuccess: true, stdout: stdout);
      }
      if (stderr.contains('ModuleNotFoundError') || stderr.contains('No module named')) {
        return null;
      }
      return ExecutionResult(isSuccess: false, stdout: stdout, stderr: stderr);
    } on ProcessException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
