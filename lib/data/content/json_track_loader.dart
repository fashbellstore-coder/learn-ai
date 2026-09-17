import 'dart:convert';

import 'package:flutter/services.dart';

import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';

/// Loads a course from `assets/content/<folder>/module_0.json` ..
/// `module_(moduleCount-1).json` — the friendly, section-based lesson/quiz
/// format the Python course established — and converts it into learn-ai's
/// [LearningModule]/[Lesson] shape so it can replace a track's seeded
/// modules while the rest of the curriculum keeps its existing content.
/// Reusable for every course: `JsonTrackLoader(folder: 'sql', trackId:
/// 'track_sql', moduleCount: 6)`, and so on.
class JsonTrackLoader {
  const JsonTrackLoader({
    required this.folder,
    required this.trackId,
    required this.moduleCount,
    String? idPrefix,
  }) : idPrefix = idPrefix ?? folder;

  /// Subfolder under assets/content/, e.g. 'python', 'sql'.
  final String folder;
  final String trackId;
  final int moduleCount;

  /// Prefix used to keep lesson/module ids unique across courses. Defaults
  /// to [folder]; pass explicitly to keep ids stable when the folder name
  /// changes (e.g. Python keeps its original 'py' prefix).
  final String idPrefix;

  /// Reads module_0.json..module_(moduleCount-1).json in order. Modules are
  /// numbered sequentially by filename, so the read order is already the
  /// course order — no extra sort key is needed. A missing or malformed
  /// module file is skipped rather than failing the whole course load.
  Future<List<LearningModule>> load({bool strict = false}) async {
    final modules = <LearningModule>[];
    for (var i = 0; i < moduleCount; i++) {
      final path = 'assets/content/$folder/module_$i.json';
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        modules.add(_moduleFromJson(json));
      } catch (error) {
        if (strict) throw FormatException('Unable to load $path: $error');
        continue;
      }
    }
    return modules;
  }

  LearningModule _moduleFromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? 'module';
    final moduleId = json['stableId'] as String? ?? '${idPrefix}_$rawId';
    final lessonsJson = (json['lessons'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return LearningModule(
      id: moduleId,
      trackId: trackId,
      title: json['title'] as String? ?? 'Module',
      description: json['description'] as String? ?? '',
      lessons: [
        for (final lessonJson in lessonsJson)
          _lessonFromJson(lessonJson, moduleId),
      ],
    );
  }

  Lesson _lessonFromJson(Map<String, dynamic> lessonJson, String moduleId) {
    final rawLessonId = lessonJson['id'] as String? ?? 'lesson';
    final lessonId =
        lessonJson['stableId'] as String? ?? '${idPrefix}_$rawLessonId';
    final sections = _sectionsFromJson(
      lessonJson['content'] as Map<String, dynamic>?,
    );
    final quizJson = lessonJson['quiz'] as Map<String, dynamic>?;
    final quizQuestions = _quizQuestionsFromJson(
      quizJson,
      lessonId,
      lessonJson['title'] as String? ?? '',
    );
    final exerciseJson = lessonJson['exercise'] as Map<String, dynamic>?;
    final codingChallenge = _exerciseFromJson(exerciseJson);
    final miniProject =
        _exerciseFromJson(lessonJson['miniProject'] as Map<String, dynamic>?) ??
        _nestedChallenge(exerciseJson);
    final mistakes = [
      for (final s in sections)
        if (s.title.toLowerCase().contains('common mistake')) s.content,
    ];
    final playgrounds = lessonJson['playgrounds'] is List
        ? [
            for (final item in lessonJson['playgrounds'] as List)
              _snippetFromJson(item as Map<String, dynamic>),
          ]
        : _playgroundsFromSections(sections);

    return Lesson(
      id: lessonId,
      trackId: trackId,
      moduleId: moduleId,
      title: lessonJson['title'] as String? ?? 'Lesson',
      subtitle: lessonJson['description'] as String? ?? '',
      readTimeMinutes: _minutesFromDuration(lessonJson['duration']),
      xpReward:
          lessonJson['xpReward'] as int? ??
          30 + (quizQuestions.isNotEmpty ? 20 : 0),
      conceptOverview: lessonJson['conceptOverview'] as String? ?? '',
      whyItMatters: lessonJson['whyItMatters'] as String? ?? '',
      eli5Explanation: lessonJson['eli5Explanation'] as String? ?? '',
      engineerDeepDive: lessonJson['engineerDeepDive'] as String? ?? '',
      realWorldAnalogy: lessonJson['realWorldAnalogy'] as String? ?? '',
      mathFormula: lessonJson['mathFormula'] as String?,
      mathIntuition: lessonJson['mathIntuition'] as String?,
      visualizerType: _enumValue(
        VisualizerType.values,
        lessonJson['visualizerType'],
        VisualizerType.none,
      ),
      keyTakeaways: _strings(lessonJson['keyTakeaways']),
      relatedProjectIds: _strings(lessonJson['relatedProjectIds']),
      relatedTechIds: _strings(lessonJson['relatedTechIds']),
      version: lessonJson['version'] as String? ?? '2026.1',
      lastUpdated: lessonJson['lastUpdated'] as String? ?? '2026-08-29',
      interviewQuestion: _interviewFromJson(
        lessonJson['interviewQuestion'] as Map<String, dynamic>?,
      ),
      debugChallenge: _exerciseFromJson(
        lessonJson['debugChallenge'] as Map<String, dynamic>?,
      ),
      predictChallenge: _predictFromJson(
        lessonJson['predictChallenge'] as Map<String, dynamic>?,
      ),
      sections: sections,
      quizQuestions: quizQuestions,
      playgrounds: playgrounds,
      codeSnippet: lessonJson['codeSnippet'] is Map<String, dynamic>
          ? _snippetFromJson(lessonJson['codeSnippet'] as Map<String, dynamic>)
          : playgrounds.isEmpty
          ? null
          : playgrounds.first,
      commonMistakes: lessonJson['commonMistakes'] is List
          ? _strings(lessonJson['commonMistakes'])
          : mistakes,
      codingChallenge: codingChallenge,
      miniProject: miniProject,
    );
  }

  List<String> _strings(Object? value) =>
      (value as List? ?? const []).cast<String>();

  T _enumValue<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;

  CodeSnippet _snippetFromJson(Map<String, dynamic> json) => CodeSnippet(
    language: _enumValue(
      CodeLanguage.values,
      json['language'],
      CodeLanguage.python,
    ),
    code: json['code'] as String,
    title: json['title'] as String? ?? 'Try this',
    explanation: json['explanation'] as String? ?? '',
    expectedOutput: json['expectedOutput'] as String? ?? '',
    isEditable: json['isEditable'] as bool? ?? true,
  );

  InterviewItem? _interviewFromJson(Map<String, dynamic>? json) => json == null
      ? null
      : InterviewItem(
          question: json['question'] as String,
          modelAnswer: json['modelAnswer'] as String,
          companyTags: _strings(json['companyTags']),
          followUpQuestions: _strings(json['followUpQuestions']),
          keyTerms: _strings(json['keyTerms']),
          topic: json['topic'] as String? ?? '',
        );

  PredictChallenge? _predictFromJson(Map<String, dynamic>? json) => json == null
      ? null
      : PredictChallenge(
          code: json['code'] as String,
          expectedOutput: json['expectedOutput'] as String,
          explanation: json['explanation'] as String? ?? '',
        );

  List<ContentSection> _sectionsFromJson(Map<String, dynamic>? content) {
    if (content == null) return const [];
    final rawSections = (content['sections'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return [
      for (final s in rawSections)
        ContentSection(
          title: s['title'] as String? ?? '',
          content: s['content'] as String? ?? '',
        ),
    ];
  }

  List<QuizQuestion> _quizQuestionsFromJson(
    Map<String, dynamic>? quiz,
    String lessonId,
    String topic,
  ) {
    if (quiz == null) return const [];
    final rawQuestions = (quiz['questions'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return [
      for (final q in rawQuestions) _questionFromJson(q, lessonId, topic),
    ];
  }

  QuizQuestion _questionFromJson(
    Map<String, dynamic> q,
    String lessonId,
    String topic,
  ) {
    final options = q['options'] as List? ?? const [];
    final correctIndex = q['correctAnswer'] as int? ?? 0;
    final qId = q['id'] as String? ?? 'q';
    return QuizQuestion(
      id: q['stableId'] as String? ?? '${lessonId}_$qId',
      question: q['question'] as String? ?? '',
      type: _enumValue(
        QuizQuestionType.values,
        q['type'],
        QuizQuestionType.singleChoice,
      ),
      options: [
        for (var i = 0; i < options.length; i++)
          QuizOption(
            id: options[i] is Map ? options[i]['id'] as String : 'opt_$i',
            text: options[i] is Map
                ? options[i]['text'] as String
                : options[i] as String,
            isCorrect: options[i] is Map
                ? options[i]['isCorrect'] as bool
                : i == correctIndex,
            explanation: options[i] is Map
                ? options[i]['explanation'] as String? ?? ''
                : '',
          ),
      ],
      explanation: q['explanation'] as String? ?? '',
      xpReward: q['xpReward'] as int? ?? 20,
      difficulty: _enumValue(
        Difficulty.values,
        q['difficulty'],
        Difficulty.medium,
      ),
      topic: q['topic'] as String? ?? topic,
      hint: q['hint'] as String? ?? '',
      codeSnippet: q['codeSnippet'] as String?,
      codeLanguage: _enumValue(
        CodeLanguage.values,
        q['codeLanguage'],
        CodeLanguage.python,
      ),
    );
  }

  CodeExercise? _exerciseFromJson(Map<String, dynamic>? exercise) {
    if (exercise == null) return null;
    final starter = (exercise['starterCode'] as String? ?? '').trimRight();
    final type = exercise['type'] as String? ?? 'code';
    final prompt = exercise['prompt'] as String? ?? '';
    if (prompt.trim().isEmpty && starter.isEmpty) return null;
    final fallbackStarter = type == 'terminal'
        ? '# This exercise is meant for a real terminal.\n# Read the prompt, then continue when you are ready.\n'
        : '# Write your code below\n';
    return CodeExercise(
      title: exercise['title'] as String? ?? 'Practice exercise',
      prompt: prompt,
      starterCode: starter.isEmpty ? fallbackStarter : '$starter\n',
      expectedOutput: exercise['expectedOutput'] as String? ?? '',
      hint: exercise['hint'] as String? ?? '',
    );
  }

  CodeExercise? _nestedChallenge(Map<String, dynamic>? exercise) {
    final raw = exercise?['challenge'];
    if (raw is! Map<String, dynamic>) return null;
    return _exerciseFromJson({...raw, 'type': raw['type'] ?? 'code'});
  }

  List<CodeSnippet> _playgroundsFromSections(List<ContentSection> sections) {
    final fence = RegExp(r'```python\n([\s\S]*?)```');
    final snippets = <CodeSnippet>[];
    for (final section in sections) {
      for (final match in fence.allMatches(section.content)) {
        final code = (match.group(1) ?? '').trimRight();
        if (code.isEmpty || snippets.any((s) => s.code == code)) continue;
        snippets.add(
          CodeSnippet(
            language: CodeLanguage.python,
            code: code,
            title: snippets.isEmpty ? 'Try this' : 'Another example',
            isEditable: true,
          ),
        );
        if (snippets.length >= 2) return snippets;
      }
    }
    return snippets;
  }

  int _minutesFromDuration(Object? duration) {
    if (duration is num) return duration.toInt();
    if (duration == null) return 10;
    final match = RegExp(r'\d+').firstMatch(duration.toString());
    if (match == null) return 10;
    return int.tryParse(match.group(0)!) ?? 10;
  }
}
