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
                            : 'Hello, $name',
                        style: type.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search the library',
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                if (profile.hasSelectedPath) ...[
                  const SizedBox(height: 8),
                  Text(profile.goal.title, style: type.titleMedium),
                  Text(profile.goal.subtitle, style: type.bodySmall),
                ],
                const SizedBox(height: 16),
                if (!fresh) ...[lessonCard, const SizedBox(height: 16)],
                _LibraryHero(courses: tracks.length, lessons: lessons.length),
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

class _LibraryHero extends StatelessWidget {
  const _LibraryHero({required this.courses, required this.lessons});
  final int courses;
  final int lessons;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final palette = context.palette;
    return FeaturePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: palette.accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ONE LIBRARY. ROOM TO GROW.',
                  style: type.labelSmall?.copyWith(
                    color: palette.accent,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Learn AI, one step at a time.',
            style: type.headlineLarge?.copyWith(
              fontSize: 32,
              height: 1.12,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'From your first Python program to building AI agents.',
            style: type.bodyMedium,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              final metrics = [
                _LibraryMetric(
                  value: courses,
                  label: 'Courses',
                  onTap: () => context.go('/learn?view=all'),
                ),
                _LibraryMetric(
                  value: lessons,
                  label: 'Lessons',
                  onTap: () => context.go('/learn?view=all'),
                ),
              ];
              return narrow
                  ? Wrap(spacing: 24, runSpacing: 12, children: metrics)
                  : Row(
                      children: [
                        for (final metric in metrics) Expanded(child: metric),
                      ],
                    );
            },
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => context.go('/learn?view=all'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Browse all courses'),
          ),
        ],
      ),
    );
  }
}

class _LibraryMetric extends StatelessWidget {
  const _LibraryMetric({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString().replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (_) => ',',
              ),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
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
    return AppCard(
      accent: palette.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fresh
                ? 'YOUR FIRST STEP · ${track.title}'
                : 'CONTINUE LEARNING · ${track.title}',
            style: type.labelSmall?.copyWith(
              color: palette.accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(lesson.title, style: type.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                label: fresh ? 'Start learning' : 'Resume lesson',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push('/lesson/${lesson.id}'),
              ),
              Text(
                '${lesson.readTimeMinutes} min · +${lesson.xpReward} XP',
                style: type.bodySmall,
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
        ],
      ),
    );
  }
}
