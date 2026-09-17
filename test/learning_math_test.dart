import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/utils/learning_math.dart';
import 'package:learn_ai/data/content/curriculum_seed.dart';
import 'package:learn_ai/data/content/interview_seed.dart';
import 'package:learn_ai/data/content/projects_seed.dart';
import 'package:learn_ai/data/content/technologies_seed.dart';
import 'package:learn_ai/shared/models/content_models.dart';
import 'package:learn_ai/shared/models/enums.dart';

void main() {
  const progress = ProgressCalculator();
  const scorer = QuizScorer();
  const streak = StreakCalculator();
  const roadmap = RoadmapGenerator();
  const search = SearchIndex();

  final tracks = const CurriculumSeed().tracks();

  test('course progress and completion', () {
    final python = tracks.firstWhere((t) => t.id == 'track_python');
    expect(progress.courseProgress(python, {}), 0);
    final all = python.lessons.map((l) => l.id).toSet();
    expect(progress.courseProgress(python, all), 1);
    expect(progress.isCourseComplete(python, all), isTrue);
    expect(progress.totalXpForTrack(python), greaterThan(0));
    final numpy = python.modules.firstWhere((m) => m.id == 'course_py_numpy');
    expect(progress.moduleProgress(numpy, {}), 0);
    expect(progress.moduleProgress(numpy, numpy.lessons.map((l) => l.id).toSet()), 1);
  });

  test('lesson status unlocks in order', () {
    final python = tracks.firstWhere((t) => t.id == 'track_python');
    final first = python.lessons.first;
    final second = python.lessons[1];
    expect(
      progress.lessonStatus(lesson: first, track: python, completedLessonIds: {}),
      LessonStatus.available,
    );
    expect(
      progress.lessonStatus(lesson: second, track: python, completedLessonIds: {}),
      LessonStatus.locked,
    );
    expect(
      progress.lessonStatus(lesson: second, track: python, completedLessonIds: {first.id}),
      LessonStatus.available,
    );
    expect(
      progress.lessonStatus(lesson: first, track: python, completedLessonIds: {first.id}),
      LessonStatus.completed,
    );
  });

  test('quiz scoring awards full XP only on exact match', () {
    const question = QuizQuestion(
      id: 'q',
      question: 'Pick both',
      type: QuizQuestionType.multipleChoice,
      options: [
        QuizOption(id: 'a', text: 'A', isCorrect: true),
        QuizOption(id: 'b', text: 'B', isCorrect: true),
        QuizOption(id: 'c', text: 'C', isCorrect: false),
      ],
      explanation: 'A and B',
      xpReward: 20,
    );
    expect(scorer.score(question, {'a', 'b'}).isCorrect, isTrue);
    expect(scorer.score(question, {'a', 'b'}).awardedXp, 20);
    expect(scorer.score(question, {'a'}).isCorrect, isFalse);
    expect(scorer.score(question, {'c'}).awardedXp, 0);
  });

  test('streak increments across consecutive days and resets after a gap', () {
    expect(streak.nextStreak(currentStreak: 0, lastActive: '', today: '2026-08-29'), 1);
    expect(streak.nextStreak(currentStreak: 4, lastActive: '2026-08-28', today: '2026-08-29'), 5);
    expect(streak.nextStreak(currentStreak: 4, lastActive: '2026-08-29', today: '2026-08-29'), 4);
    expect(streak.nextStreak(currentStreak: 4, lastActive: '2026-08-26', today: '2026-08-29'), 1);
    expect(streak.isBroken(lastActive: '2026-08-26', today: '2026-08-29'), isTrue);
  });

  test('roadmap generation respects career goal and skips python for experts', () {
    final junior = roadmap.generate(
      goal: CareerGoal.agentEngineer,
      level: SkillLevel.beginner,
      dailyMinutes: 30,
    );
    expect(junior.first, 'track_python');
    expect(junior, contains('track_mcp'));

    final expert = roadmap.generate(
      goal: CareerGoal.agentEngineer,
      level: SkillLevel.expert,
      dailyMinutes: 30,
    );
    expect(expert, isNot(contains('track_python')));
  });

  test('search returns categorized hits for attention', () {
    final hits = search.query(
      rawQuery: 'attention',
      tracks: tracks,
      projects: const ProjectsSeed().all(),
      technologies: const TechnologiesSeed().all(),
      interviews: const InterviewSeed().bank(),
    );
    expect(hits, isNotEmpty);
    expect(hits.any((h) => h.category == 'Lesson'), isTrue);
  });
}
