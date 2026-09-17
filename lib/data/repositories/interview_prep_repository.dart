import 'dart:convert';

import 'package:flutter/services.dart';

import '../../shared/models/interview_models.dart';

class InterviewPrepRepository {
  final Map<String, Future<InterviewBank>> _cache = {};
  Future<InterviewBank> load(String courseId) =>
      _cache.putIfAbsent(courseId, () => _load(courseId));
  void retry(String courseId) => _cache.remove(courseId);
  Future<InterviewBank> _load(String courseId) async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/content/courses.json'),
    ) as Map<String, dynamic>;
    final entry = (manifest['courses'] as List)
        .cast<Map<String, dynamic>>()
        .where((c) => c['trackId'] == courseId)
        .firstOrNull;
    if (entry == null) {
      throw FormatException('Unknown interview course: $courseId');
    }
    final json = jsonDecode(
      await rootBundle.loadString(
        'assets/content/${entry['folder']}/interview.json',
      ),
    ) as Map<String, dynamic>;
    final questions = (json['questions'] as List)
        .map((q) => PrepQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    final pools = (json['pools'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
    final ids = questions.map((q) => q.id).toSet();
    if (json['courseId'] != courseId || ids.length != questions.length) {
      throw const FormatException('Invalid question bank identity');
    }
    for (final q in questions) {
      if (q.prompt.isEmpty ||
          q.answer.isEmpty ||
          q.keyPoints.isEmpty ||
          !ids.containsAll(q.followUpIds)) {
        throw FormatException('Incomplete question ${q.id}');
      }
      final choices = q.choices.map((c) => c.id).toSet();
      if (choices.length != q.choices.length) {
        throw FormatException('Duplicate options ${q.id}');
      }
      if (q.objective &&
          q.format != InterviewFormat.codeOutput &&
          (q.correctIds.isEmpty || !choices.containsAll(q.correctIds))) {
        throw FormatException('Invalid answer key ${q.id}');
      }
      if (q.format == InterviewFormat.ordering &&
          q.correctIds.length != choices.length) {
        throw FormatException('Invalid ordering ${q.id}');
      }
    }
    void visit(String id, Set<String> path) {
      if (!path.add(id)) throw FormatException('Cyclic follow-up tree: $id');
      for (final next in questions.firstWhere((q) => q.id == id).followUpIds) {
        visit(next, {...path});
      }
    }

    for (final q in questions) {
      visit(q.id, {});
    }
    for (final mode in InterviewMode.values) {
      final pool = pools[mode.name];
      if (pool == null ||
          pool.isEmpty ||
          !ids.containsAll(pool) ||
          pool.toSet().length != pool.length) {
        throw FormatException('Invalid ${mode.name} pool');
      }
    }
    return InterviewBank(
      courseId: courseId,
      questions: questions,
      pools: pools,
    );
  }
}
