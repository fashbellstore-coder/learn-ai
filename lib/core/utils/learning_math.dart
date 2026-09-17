import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_models.dart';

class ProgressCalculator {
  const ProgressCalculator();

  double courseProgress(RoadmapTrack track, Set<String> completedLessonIds) {
    final lessons = track.lessons;
    if (lessons.isEmpty) return 0;
    final done = lessons.where((l) => completedLessonIds.contains(l.id)).length;
    return done / lessons.length;
  }

  double moduleProgress(LearningModule module, Set<String> completedLessonIds) {
    if (module.lessons.isEmpty) return 0;
    final done = module.lessons
        .where((l) => completedLessonIds.contains(l.id))
        .length;
    return done / module.lessons.length;
  }

  bool isCourseComplete(RoadmapTrack track, Set<String> completedLessonIds) {
    return track.lessons.isNotEmpty &&
        track.lessons.every((l) => completedLessonIds.contains(l.id));
  }

  LessonStatus lessonStatus({
    required Lesson lesson,
    required RoadmapTrack track,
    required Set<String> completedLessonIds,
  }) {
    if (completedLessonIds.contains(lesson.id)) return LessonStatus.completed;
    final all = track.lessons;
    final index = all.indexWhere((l) => l.id == lesson.id);
    if (index <= 0) return LessonStatus.available;
    final previous = all[index - 1];
    if (completedLessonIds.contains(previous.id)) return LessonStatus.available;
    return LessonStatus.locked;
  }

  int totalXpForTrack(RoadmapTrack track) =>
      track.lessons.fold(0, (sum, lesson) => sum + lesson.xpReward);
}

class QuizScorer {
  const QuizScorer();

  QuizScore score(QuizQuestion question, Set<String> selectedOptionIds) {
    final correctIds = question.options
        .where((o) => o.isCorrect)
        .map((o) => o.id)
        .toSet();
    final selected = selectedOptionIds;
    final isPerfect =
        selected.length == correctIds.length &&
        selected.containsAll(correctIds);
    final overlap = selected.intersection(correctIds).length;
    final precision = selected.isEmpty ? 0.0 : overlap / selected.length;
    final recall = correctIds.isEmpty ? 0.0 : overlap / correctIds.length;
    final xp = isPerfect
        ? question.xpReward
        : (question.xpReward * 0.25 * recall).round();
    return QuizScore(
      isCorrect: isPerfect,
      awardedXp: xp,
      precision: precision,
      recall: recall,
    );
  }

  int totalXp(List<QuizScore> scores) =>
      scores.fold(0, (sum, s) => sum + s.awardedXp);
}

class QuizScore {
  const QuizScore({
    required this.isCorrect,
    required this.awardedXp,
    required this.precision,
    required this.recall,
  });

  final bool isCorrect;
  final int awardedXp;
  final double precision;
  final double recall;
}

class StreakCalculator {
  const StreakCalculator();

  /// [today] and [lastActive] are ISO dates `yyyy-MM-dd`.
  int nextStreak({
    required int currentStreak,
    required String lastActive,
    required String today,
  }) {
    if (lastActive.isEmpty) return 1;
    if (lastActive == today) return currentStreak == 0 ? 1 : currentStreak;
    final last = DateTime.tryParse(lastActive);
    final now = DateTime.tryParse(today);
    if (last == null || now == null) return 1;
    final gap = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(last.year, last.month, last.day)).inDays;
    if (gap == 1) return currentStreak + 1;
    if (gap <= 0) return currentStreak;
    return 1;
  }

  bool isBroken({required String lastActive, required String today}) {
    if (lastActive.isEmpty) return false;
    final last = DateTime.tryParse(lastActive);
    final now = DateTime.tryParse(today);
    if (last == null || now == null) return false;
    return DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(last.year, last.month, last.day)).inDays >
        1;
  }
}

class RoadmapGenerator {
  const RoadmapGenerator();

  List<String> generate({
    required CareerGoal goal,
    required SkillLevel level,
    required int dailyMinutes,
  }) {
    final foundations = [
      'track_python',
      'track_math',
      'track_sql',
      'track_ds',
      'track_swe',
    ];
    final coreMl = ['track_ml', 'track_dl', 'track_pytorch'];
    final language = [
      'track_nlp',
      'track_transformers',
      'track_llm_architecture',
      'track_hf',
      'track_genai',
      'track_prompt_engineering',
    ];
    final systems = [
      'track_llm',
      'track_embeddings',
      'track_vectordb',
      'track_rag',
      'track_inference',
    ];
    final agents = [
      'track_agents',
      'track_langgraph',
      'track_mcp',
      'track_advanced_agents',
      'track_ai_security',
    ];
    final production = [
      'track_mlops',
      'track_llmops',
      'track_eval_security',
      'track_appdev',
      'track_cloud',
      'track_enterprise',
    ];

    var path = switch (goal) {
      CareerGoal.mlEngineer => [
        ...foundations,
        ...coreMl,
        'track_cv',
        'track_mlops',
      ],
      CareerGoal.llmEngineer => [
        ...foundations,
        'track_ml',
        'track_dl',
        ...language,
        ...systems,
        'track_finetune',
        'track_multimodal',
        'track_graphrag',
      ],
      CareerGoal.agentEngineer => [
        ...foundations,
        'track_dl',
        ...language,
        ...systems,
        ...agents,
      ],
      CareerGoal.cvEngineer => [
        ...foundations,
        ...coreMl,
        'track_cv',
        'track_mlops',
      ],
      CareerGoal.nlpEngineer => [
        ...foundations,
        'track_ml',
        'track_dl',
        ...language,
        'track_embeddings',
        'track_rag',
      ],
      CareerGoal.mlopsEngineer => [
        ...foundations,
        'track_ml',
        'track_dl',
        ...production,
        'track_inference',
        'track_distributed',
        'track_system_design',
      ],
      CareerGoal.researcher => [
        ...foundations,
        'track_advanced_math',
        ...coreMl,
        'track_transformers',
        'track_llm_architecture',
        'track_finetune',
        'track_distributed',
        'track_reasoning',
        'track_research',
      ],
      CareerGoal.aiEngineer => [
        ...foundations,
        ...coreMl,
        'track_transformers',
        'track_genai',
        'track_prompt_engineering',
        ...systems,
        ...agents,
        ...production,
      ],
    };

    if (level == SkillLevel.advanced || level == SkillLevel.expert) {
      path = path.where((id) => id != 'track_python').toList();
    }
    // Daily time changes pacing, never removes a learner's destination courses.
    return path;
  }
}

class SearchIndex {
  const SearchIndex();

  List<SearchHit> query({
    required String rawQuery,
    required List<RoadmapTrack> tracks,
    required List<Project> projects,
    required List<TechnologyItem> technologies,
    required List<InterviewItem> interviews,
  }) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = <SearchHit>[];

    for (final track in tracks) {
      if (_matches(q, [track.title, track.tagline, ...track.keySkills])) {
        hits.add(
          SearchHit(
            id: track.id,
            title: track.title,
            subtitle: track.tagline,
            category: 'Course',
            route: '/course/${track.id}',
          ),
        );
      }
      for (final lesson in track.lessons) {
        if (_matches(q, [
          lesson.title,
          lesson.subtitle,
          lesson.conceptOverview,
          ...lesson.keyTakeaways,
          ...lesson.sections.map((s) => '${s.title} ${s.content}'),
        ])) {
          hits.add(
            SearchHit(
              id: lesson.id,
              title: lesson.title,
              subtitle: lesson.subtitle,
              category: 'Lesson',
              route: '/lesson/${lesson.id}',
            ),
          );
        }
      }
    }

    for (final project in projects) {
      if (_matches(q, [
        project.title,
        project.subtitle,
        project.category,
        ...project.techStack,
      ])) {
        hits.add(
          SearchHit(
            id: project.id,
            title: project.title,
            subtitle: project.subtitle,
            category: 'Project',
            route: '/project/${project.id}',
          ),
        );
      }
    }

    for (final tech in technologies) {
      if (_matches(q, [
        tech.name,
        tech.tagline,
        tech.whatItIs,
        ...tech.alternatives,
      ])) {
        hits.add(
          SearchHit(
            id: tech.id,
            title: tech.name,
            subtitle: tech.tagline,
            category: 'Technology',
            route: '/tech/${tech.id}',
          ),
        );
      }
    }

    for (final item in interviews) {
      if (_matches(q, [item.question, item.topic, ...item.keyTerms])) {
        hits.add(
          SearchHit(
            id: item.question,
            title: item.question,
            subtitle: item.topic.isEmpty ? 'Interview' : item.topic,
            category: 'Interview',
            route: '/interview',
          ),
        );
      }
    }

    return hits.take(40).toList();
  }

  bool _matches(String q, List<String> fields) {
    return fields.any((f) => f.toLowerCase().contains(q));
  }
}

class DailyPlanner {
  const DailyPlanner();

  List<DailyPlanItem> plan({
    required UserProfile profile,
    required List<RoadmapTrack> tracks,
    required List<Project> projects,
  }) {
    RoadmapTrack current = tracks.first;
    for (final track in tracks) {
      if (track.id == profile.currentTrackId) current = track;
    }
    Lesson? next;
    for (final lesson in current.lessons) {
      if (!profile.completedLessonIds.contains(lesson.id)) {
        next = lesson;
        break;
      }
    }
    next ??= current.lessons.isEmpty ? null : current.lessons.first;
    Project? project;
    for (final p in projects) {
      if (!profile.completedProjectIds.contains(p.id)) {
        project = p;
        break;
      }
    }
    return [
      if (next != null)
        DailyPlanItem(
          title: next.title,
          minutes: next.readTimeMinutes.clamp(6, 12).toInt(),
          kind: 'Learn',
          lessonId: next.id,
        ),
      const DailyPlanItem(title: 'Spaced quiz', minutes: 5, kind: 'Practice'),
      if (project != null)
        DailyPlanItem(title: project.title, minutes: 7, kind: 'Build'),
    ];
  }
}
