import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../core/utils/learning_math.dart';
import '../../shared/models/content_models.dart';
import '../../shared/widgets/app_primitives.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final tracks = ref.watch(tracksProvider);
    final lessons = tracks.expand((t) => t.lessons).toList();
    final path = ref
        .watch(roadmapGeneratorProvider)
        .generate(
          goal: profile.goal,
          level: profile.skillLevel,
          dailyMinutes: profile.dailyGoalMinutes,
        );
    final ordered = <RoadmapTrack>[
      ...tracks.where((t) => t.id == profile.currentTrackId),
      if (profile.hasSelectedPath)
        for (final id in path)
          ...tracks.where((t) => t.id == id && t.id != profile.currentTrackId),
      ...tracks.where(
        (t) =>
            t.id != profile.currentTrackId &&
            (!profile.hasSelectedPath || !path.contains(t.id)),
      ),
    ];
    final next = ordered
        .expand((t) => t.lessons)
        .where((l) => !profile.completedLessonIds.contains(l.id))
        .firstOrNull;
    final current = next == null
        ? null
        : tracks.where((t) => t.id == next.trackId).firstOrNull;
    final fresh = profile.completedLessonIds.isEmpty;
    final type = Theme.of(context).textTheme;
    final name = profile.name.trim().split(RegExp(r'\s+')).first;
    final lessonCard = next != null && current != null
        ? _NextLesson(
            track: current,
            lesson: next,
            fresh: fresh,
            completed: profile.completedLessonIds,
          )
        : AppCard(
            onTap: () => context.go('/learn?view=all'),
            child: Text(
              lessons.isEmpty
                  ? 'Your courses will appear here.'
                  : 'All lessons complete. Revisit a favorite course.',
              style: type.titleMedium,
            ),
          );
    final libraryTracks = ordered
        .where((t) => current == null || t.id != current.id)
        .take(4)
        .toList();
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-simple'),
        slivers: [
          SliverPadding(
            padding: pageInsets(context, top: 16, bottom: 32),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty || name == 'Learner'
                            ? 'Welcome to Learn AI'
                            : 'Welcome back, $name',
                        style: type.titleLarge,
                      ),
                    ),
                    _StreakChip(days: profile.streakDays),
                    IconButton(
                      tooltip: 'Search the library',
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MonoChip(label: 'LEVEL ${profile.level}'),
                    MonoChip(label: '${profile.xp} XP'),
                    if (profile.hasSelectedPath)
                      MonoChip(label: profile.goal.title.toUpperCase()),
                  ],
                ),
                if (profile.hasSelectedPath) ...[
                  const SizedBox(height: 8),
                  Text(profile.goal.subtitle, style: type.bodySmall),
                ],
                const SizedBox(height: 18),
                if (!fresh) ...[lessonCard, const SizedBox(height: 20)],
                _LibrarySection(
                  courses: tracks.length,
                  lessons: lessons.length,
                  tracks: libraryTracks,
                  completed: profile.completedLessonIds,
                ),
                const SizedBox(height: 16),
                if (fresh) ...[lessonCard, const SizedBox(height: 24)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, size: 14, color: palette.warning),
            const SizedBox(width: 4),
            Text(
              '$days',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: palette.warning),
            ),
          ],
        ),
      ),
    );
  }
}

/// The compact "Your library" list — a course-list card per track showing
/// its subject, the next lesson due (or completion state), and progress,
/// matching design_inspire's Home Dashboard mockup.
class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.courses,
    required this.lessons,
    required this.tracks,
    required this.completed,
  });

  final int courses;
  final int lessons;
  final List<RoadmapTrack> tracks;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final palette = context.palette;
    const calc = ProgressCalculator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Your library', style: type.titleMedium)),
            Text(
              '$courses COURSES',
              style: type.labelMedium?.copyWith(color: palette.success),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final track in tracks) ...[
          _CourseRow(
            track: track,
            done: calc.isCourseComplete(track, completed),
            completedCount: track.lessons
                .where((l) => completed.contains(l.id))
                .length,
          ),
          const SizedBox(height: 10),
        ],
        TextButton.icon(
          onPressed: () => context.go('/learn?view=all'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text('Browse all $courses courses ($lessons lessons)'),
        ),
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.track,
    required this.done,
    required this.completedCount,
  });

  final RoadmapTrack track;
  final bool done;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = Theme.of(context).textTheme;
    final total = track.lessons.length;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/course/${track.id}'),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done ? palette.success : palette.elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.menu_book_outlined,
              size: 17,
              color: done ? palette.onAccent : palette.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.titleMedium,
                ),
                if (done) ...[
                  const SizedBox(height: 2),
                  Text(
                    'COMPLETE',
                    style: type.labelSmall?.copyWith(color: palette.success),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$completedCount/$total',
            style: type.labelMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NextLesson extends StatelessWidget {
  const _NextLesson({
    required this.track,
    required this.lesson,
    required this.fresh,
    required this.completed,
  });
  final RoadmapTrack track;
  final Lesson lesson;
  final bool fresh;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final palette = context.palette;
    final index = track.lessons.indexWhere((l) => l.id == lesson.id);
    return AppCard(
      accent: palette.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fresh ? 'YOUR FIRST STEP' : 'CONTINUE LEARNING',
                  style: type.labelMedium?.copyWith(color: palette.success),
                ),
              ),
              if (!fresh && index >= 0)
                Text(
                  'LESSON ${index + 1} / ${track.lessons.length}',
                  style: type.labelMedium?.copyWith(color: palette.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bolt_rounded, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: type.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(lesson.title, style: type.titleLarge),
                  ],
                ),
              ),
            ],
          ),
          if (!fresh) ...[
            const SizedBox(height: 14),
            AppProgressBar(
              value: const ProgressCalculator().courseProgress(
                track,
                completed,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                label: fresh ? 'Start learning' : 'Resume lesson',
                icon: Icons.play_arrow_rounded,
                expand: false,
                onPressed: () => context.push('/lesson/${lesson.id}'),
              ),
              Text(
                '${lesson.readTimeMinutes} min · +${lesson.xpReward} XP',
                style: type.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
