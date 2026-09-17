import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';

Lesson lesson({
  required String id,
  required String trackId,
  required String moduleId,
  required String title,
  required String subtitle,
  required int minutes,
  required int xp,
  required String concept,
  required String why,
  required String eli5,
  required String engineer,
  required String analogy,
  String? formula,
  String? mathIntuition,
  VisualizerType visualizer = VisualizerType.none,
  CodeSnippet? code,
  List<CodeSnippet> playgrounds = const [],
  List<String> mistakes = const [],
  InterviewItem? interview,
  List<QuizQuestion> quiz = const [],
  List<String> takeaways = const [],
  List<String> tech = const [],
  List<String> projects = const [],
  PredictChallenge? predict,
  CodeExercise? debug,
  CodeExercise? coding,
  CodeExercise? mini,
}) {
  return Lesson(
    id: id,
    trackId: trackId,
    moduleId: moduleId,
    title: title,
    subtitle: subtitle,
    readTimeMinutes: minutes,
    xpReward: xp,
    conceptOverview: concept,
    whyItMatters: why,
    eli5Explanation: eli5,
    engineerDeepDive: engineer,
    realWorldAnalogy: analogy,
    mathFormula: formula,
    mathIntuition: mathIntuition,
    visualizerType: visualizer,
    codeSnippet: playgrounds.isNotEmpty ? playgrounds.first : code,
    playgrounds: playgrounds,
    commonMistakes: mistakes,
    interviewQuestion: interview,
    quizQuestions: quiz,
    keyTakeaways: takeaways,
    relatedTechIds: tech,
    relatedProjectIds: projects,
    predictChallenge: predict,
    debugChallenge: debug,
    codingChallenge: coding,
    miniProject: mini,
  );
}

QuizQuestion mcq({
  required String id,
  required String question,
  required List<QuizOption> options,
  required String explanation,
  QuizQuestionType type = QuizQuestionType.singleChoice,
  Difficulty difficulty = Difficulty.medium,
  String topic = '',
  int xp = 25,
  String hint = '',
  String? code,
}) {
  return QuizQuestion(
    id: id,
    question: question,
    type: type,
    options: options,
    explanation: explanation,
    difficulty: difficulty,
    topic: topic,
    xpReward: xp,
    hint: hint,
    codeSnippet: code,
  );
}

QuizOption opt(String id, String text, bool correct, [String explanation = '']) {
  return QuizOption(id: id, text: text, isCorrect: correct, explanation: explanation);
}

CodeSnippet py(String title, String code, {String explanation = '', String expected = ''}) {
  return CodeSnippet(
    language: CodeLanguage.python,
    title: title,
    code: code.trim(),
    explanation: explanation,
    expectedOutput: expected,
  );
}

/// Compact complete lesson used for full-track syllabi.
Lesson unit({
  required String id,
  required String trackId,
  required String moduleId,
  required String title,
  required String subtitle,
  required String what,
  required String why,
  required String how,
  required String quiz,
  required String correct,
  List<String> wrong = const ['Unrelated', 'The opposite', 'Not how production systems work'],
  String? eli5,
  String? analogy,
  String? code,
  String? expected,
  String? code2,
  String? expected2,
  String example1 = 'Example 1 — run this',
  String example2 = 'Example 2 — try this too',
  String? formula,
  List<String> takeaways = const [],
  List<String> mistakes = const [],
  int minutes = 12,
  int xp = 55,
  VisualizerType visualizer = VisualizerType.none,
}) {
  final opts = <QuizOption>[
    opt('1', correct, true),
    for (var i = 0; i < wrong.length; i++) opt('${i + 2}', wrong[i], false),
  ];
  final scoped = what.contains('\n')
      ? what
      : '$what\n\nThis lesson stays on "$title" alone. Neighboring ideas get their own lessons so you can practice one contract at a time.';
  final practice = how.contains('\n')
      ? how
      : '$how\n\nWrite the smallest example that would fail if you confused this with a neighboring topic. Keep that example. When a library wraps the idea later, you should still be able to point at this contract.';
  return lesson(
    id: id,
    trackId: trackId,
    moduleId: moduleId,
    title: title,
    subtitle: subtitle,
    minutes: minutes,
    xp: xp,
    concept: scoped,
    why: why,
    eli5: eli5 ?? 'In plain words: $what',
    engineer: practice,
    analogy: analogy ?? 'Treat "$title" like a labeled tool — one job, one contract, one way it breaks.',
    formula: formula,
    visualizer: visualizer,
    code: code == null ? null : py(example1, code, expected: expected ?? ''),
    playgrounds: [
      if (code != null) py(example1, code, expected: expected ?? ''),
      if (code2 != null) py(example2, code2, expected: expected2 ?? ''),
    ],
    mistakes: mistakes.isEmpty
        ? [
            'Bundling this topic with a neighbor and never practicing it alone.',
            'Skipping a tiny example and jumping straight to a framework.',
            'Memorizing a slogan instead of the actual contract (shape, mutability, or metric).',
          ]
        : mistakes,
    quiz: [
      mcq(
        id: 'q_$id',
        question: quiz,
        options: opts,
        explanation: correct,
        topic: title,
      ),
    ],
    takeaways: takeaways.isEmpty ? [what, 'Practice this idea in isolation before combining it.'] : takeaways,
    predict: code == null
        ? null
        : PredictChallenge(code: code.trim(), expectedOutput: expected ?? ''),
    debug: code == null
        ? null
        : CodeExercise(
            title: 'Debug challenge',
            prompt: 'This version is broken. Fix it so it prints the expected result.',
            starterCode: 'print("TODO")\n# Fix this so it matches the expected output for "$title".',
            expectedOutput: expected ?? '',
            hint: 'Start from Example 1 and restore the real print.',
          ),
    coding: (code2 ?? code) == null
        ? null
        : CodeExercise(
            title: 'Coding challenge',
            prompt: 'Write a small program that uses "$title" and prints a clear result.',
            starterCode: '# Your code here\n',
            expectedOutput: expected2 ?? expected ?? '',
            hint: 'Use Example 2 as a model, then change one value.',
          ),
    mini: code == null
        ? null
        : CodeExercise(
            title: 'Mini project',
            prompt: 'Apply "$title" to a tiny real task. Keep it under 15 lines.',
            starterCode: '# Mini project: $title\n',
            expectedOutput: expected ?? '',
            hint: 'Combine the examples into one short script.',
          ),
  );
}

InterviewItem interview({
  required String question,
  required String answer,
  List<String> followUps = const [],
  List<String> terms = const [],
  String topic = '',
}) {
  return InterviewItem(
    question: question,
    modelAnswer: answer,
    followUpQuestions: followUps,
    keyTerms: terms,
    topic: topic,
  );
}
