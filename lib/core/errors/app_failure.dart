enum FailureKind {
  network,
  server,
  auth,
  empty,
  codeExecution,
  tutor,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.title,
    required this.message,
  });

  final FailureKind kind;
  final String title;
  final String message;

  factory AppFailure.network() => const AppFailure(
        kind: FailureKind.network,
        title: 'You’re offline',
        message: 'Cached lessons stay available. Progress syncs when you reconnect.',
      );

  factory AppFailure.server() => const AppFailure(
        kind: FailureKind.server,
        title: 'Learn AI is unavailable',
        message: 'We couldn’t reach the learning service. Try again in a moment.',
      );

  factory AppFailure.auth() => const AppFailure(
        kind: FailureKind.auth,
        title: 'Sign-in required',
        message: 'Your session expired. Sign in again to continue tracking progress.',
      );

  factory AppFailure.empty(String message) => AppFailure(
        kind: FailureKind.empty,
        title: 'Nothing to show',
        message: message,
      );

  factory AppFailure.code() => const AppFailure(
        kind: FailureKind.codeExecution,
        title: 'Code didn’t run',
        message: 'Check syntax and try again. The sandbox never executes remotely in this build.',
      );

  factory AppFailure.tutor() => const AppFailure(
        kind: FailureKind.tutor,
        title: 'Tutor is thinking…',
        message: 'The tutor couldn’t generate a reply. Ask again or rephrase the question.',
      );

  @override
  String toString() => message;
}
