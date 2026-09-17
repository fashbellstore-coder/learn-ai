enum InterviewFormat {
  concept,
  mcq,
  multiSelect,
  trueFalse,
  codeOutput,
  debugging,
  architecture,
  ordering,
  flashcard,
  scenario,
}

extension InterviewFormatLabel on InterviewFormat {
  String get label => switch (this) {
    InterviewFormat.concept => 'Concept',
    InterviewFormat.mcq => 'Multiple choice',
    InterviewFormat.multiSelect => 'Select all that apply',
    InterviewFormat.trueFalse => 'True / False',
    InterviewFormat.codeOutput => 'Code output',
    InterviewFormat.debugging => 'Debugging',
    InterviewFormat.architecture => 'Architecture',
    InterviewFormat.ordering => 'Ordering',
    InterviewFormat.flashcard => 'Flashcard',
    InterviewFormat.scenario => 'Scenario',
  };
}

enum InterviewMode {
  practice(
    'Practice',
    'Reference answers are visible. Explore the question trees.',
  ),
  interview('Interview', 'Answer first, then reveal. Track your time locally.'),
  rapidFire('Rapid Fire', '20 short questions. Keep answers concise.'),
  scenario(
    'Scenario',
    'Work through production failures and design decisions.',
  ),
  mock(
    'Mock Interview',
    '10 predefined questions with objective and self-assessed results.',
  );

  const InterviewMode(this.label, this.description);
  final String label, description;
}

class InterviewChoice {
  const InterviewChoice(this.id, this.text);
  final String id, text;
}

class PrepQuestion {
  const PrepQuestion({
    required this.id,
    required this.prompt,
    required this.format,
    required this.answer,
    required this.keyPoints,
    required this.category,
    this.choices = const [],
    this.correctIds = const [],
    this.expectedOutput = '',
    this.code = '',
    this.followUpIds = const [],
    this.difficulty = 'Foundation',
  });
  final String id, prompt, answer, category, expectedOutput, code, difficulty;
  final InterviewFormat format;
  final List<String> keyPoints, correctIds, followUpIds;
  final List<InterviewChoice> choices;
  bool get objective => {
    InterviewFormat.mcq,
    InterviewFormat.multiSelect,
    InterviewFormat.trueFalse,
    InterviewFormat.codeOutput,
    InterviewFormat.debugging,
    InterviewFormat.architecture,
    InterviewFormat.ordering,
  }.contains(format);
  factory PrepQuestion.fromJson(Map<String, dynamic> json) => PrepQuestion(
    id: json['id'] as String,
    prompt: json['prompt'] as String,
    format: InterviewFormat.values.byName(json['format'] as String),
    answer: json['referenceAnswer'] as String,
    keyPoints: List<String>.from(json['keyPoints'] as List),
    category: json['category'] as String,
    choices: [
      for (final c in json['choices'] as List? ?? [])
        InterviewChoice(c['id'] as String, c['text'] as String),
    ],
    correctIds: List<String>.from(json['correctIds'] as List? ?? []),
    followUpIds: List<String>.from(json['followUpIds'] as List? ?? []),
    expectedOutput: json['expectedOutput'] as String? ?? '',
    code: json['code'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'Foundation',
  );
}

class InterviewBank {
  const InterviewBank({
    required this.courseId,
    required this.questions,
    required this.pools,
  });
  final String courseId;
  final List<PrepQuestion> questions;
  final Map<String, List<String>> pools;
  PrepQuestion question(String id) => questions.firstWhere((q) => q.id == id);
  List<PrepQuestion> session(InterviewMode mode) => [
    for (final id in pools[mode.name]!) question(id),
  ];
}

class PrepResponse {
  final selected = <String>{};
  final points = <int>{};
  List<String> order = [];
  String text = '';
  bool revealed = false, submitted = false;
  bool? correct;
  int seconds = 0;
}

/// Free text is never interpreted or graded. Objective formats use exact keys.
bool scoreInterviewAnswer(PrepQuestion q, PrepResponse response) {
  if (!q.objective) {
    throw ArgumentError('Free-text answers require self-assessment.');
  }
  if (q.format == InterviewFormat.codeOutput) {
    return response.text.trim().replaceAll('\r\n', '\n') ==
        q.expectedOutput.trim().replaceAll('\r\n', '\n');
  }
  if (q.format == InterviewFormat.ordering) {
    return response.order.length == q.correctIds.length &&
        List.generate(
          q.correctIds.length,
          (i) => response.order[i] == q.correctIds[i],
        ).every((v) => v);
  }
  return response.selected.length == q.correctIds.length &&
      response.selected.containsAll(q.correctIds);
}
