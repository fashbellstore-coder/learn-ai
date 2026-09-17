import 'dart:convert';

import 'package:flutter/services.dart';

import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';

class PracticeBankBundle {
  const PracticeBankBundle({
    required this.drills,
    required this.interviews,
  });

  final List<QuizQuestion> drills;
  final List<InterviewItem> interviews;
}

class PracticeBankLoader {
  const PracticeBankLoader({this.assetPath = 'assets/content/python/practice_bank.json'});

  final String assetPath;

  Future<PracticeBankBundle> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return parse(raw);
    } catch (_) {
      return const PracticeBankBundle(drills: [], interviews: []);
    }
  }

  static PracticeBankBundle parse(String raw) {
    final decoded = jsonDecode(raw);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (items is! List) {
      return const PracticeBankBundle(drills: [], interviews: []);
    }

    final drills = <QuizQuestion>[];
    final interviews = <InterviewItem>[];
    for (final item in items) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final question = _questionFromJson(map);
      if (question == null) continue;
      drills.add(question);
      if (map['interview'] == true || map['kind'] == 'interview') {
        interviews.add(
          InterviewItem(
            question: question.question,
            modelAnswer: question.explanation,
            topic: map['moduleTitle'] as String? ?? 'Python',
            keyTerms: const ['Python'],
          ),
        );
      }
    }
    return PracticeBankBundle(drills: drills, interviews: interviews);
  }

  static QuizQuestion? _questionFromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List? ?? const []).cast<String>();
    final correctIndex = json['correctAnswer'];
    if (options.length < 2 || correctIndex is! int || correctIndex < 0 || correctIndex >= options.length) {
      return null;
    }
    final id = json['id'] as String? ?? 'practice';
    final kind = json['kind'] as String? ?? 'recall';
    return QuizQuestion(
      id: id,
      question: json['question'] as String? ?? '',
      type: switch (kind) {
        'debug' => QuizQuestionType.debug,
        'output' => QuizQuestionType.codeOutput,
        'interview' => QuizQuestionType.conceptual,
        _ => QuizQuestionType.conceptual,
      },
      options: [
        for (var i = 0; i < options.length; i++)
          QuizOption(id: '${id}_opt_$i', text: options[i], isCorrect: i == correctIndex),
      ],
      explanation: json['explanation'] as String? ?? '',
      xpReward: 15,
      difficulty: switch ((json['difficulty'] as String? ?? 'medium').toLowerCase()) {
        'easy' => Difficulty.easy,
        'hard' => Difficulty.hard,
        'expert' => Difficulty.expert,
        _ => Difficulty.medium,
      },
      topic: json['moduleTitle'] as String? ?? 'Python',
    );
  }
}
