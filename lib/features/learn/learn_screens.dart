import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/content/learning_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_extras.dart';
import '../../core/utils/learning_math.dart';
import '../../shared/models/content_models.dart';
import '../../shared/widgets/app_primitives.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key, this.showAll = false});

  final bool showAll;

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  late bool _showAll;
  LearningPath? _selectedPath;

  @override
  void initState() {
    super.initState();
    _showAll = widget.showAll;
  }

  @override
  void didUpdateWidget(covariant LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAll != widget.showAll) _showAll = widget.showAll;
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final profile = ref.watch(userProfileProvider);
    final pathIds = ref
        .watch(roadmapGeneratorProvider)
        .generate(
          goal: profile.goal,
          level: profile.skillLevel,
          dailyMinutes: profile.dailyGoalMinutes,
        );
    final path = profile.hasSelectedPath
        ? [for (final id in pathIds) ...tracks.where((track) => track.id == id)]
        : tracks;
    final visible = _selectedPath != null
        ? [
            for (final id in _selectedPath!.courseIds)
              ...tracks.where((t) => t.id == id),
          ]
        : _showAll
        ? tracks
        : path;
    final current = tracks
        .where((t) => t.id == profile.currentTrackId)
        .firstOrNull;
    final type = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Learn'),
          actions: [
            IconButton(
              tooltip: 'View course map',
              onPressed: () => context.push('/course-map'),
              icon: const Icon(Icons.account_tree_outlined),
            ),
            IconButton(
              tooltip: 'Search lessons',
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 12),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your learning library',
                      style: type.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a direction. Share foundations. Build real systems.',
                      style: type.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('My path · ${path.length}'),
                          selected: !_showAll && _selectedPath == null,
                          onSelected: (_) => setState(() {
                            _showAll = false;
                            _selectedPath = null;
                          }),
                          showCheckmark: false,
                        ),
                        ChoiceChip(
                          label: Text('All courses · ${tracks.length}'),
                          selected: _showAll && _selectedPath == null,
                          onSelected: (_) => setState(() {
                            _showAll = true;
                            _selectedPath = null;
                          }),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LearningPath>(
                      key: ValueKey(_selectedPath?.id),
                      initialValue: _selectedPath,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Explore a career track',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final path in learningPaths)
                          DropdownMenuItem(
                            value: path,
                            child: Text(
                              path.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedPath = value),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedPath?.description ?? 'Courses are open to explore. Prerequisites are guidance, not a single mandatory ladder.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/projects'),
                          icon: const Icon(Icons.construction),
                          label: const Text('Portfolio projects'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/labs'),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Experiment lab'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 700 ? 2 : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 16) /
                            columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (var i = 0; i < visible.length; i++)
                              SizedBox(
                                width: width,
                                child: _LearnCourseTile(
                                  track: visible[i],
                                  index: i + 1,
                                  active: visible[i].id == current?.id,
                                  completed: profile.completedLessonIds,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('Your courses will appear here.'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _LearnCourseTile extends StatelessWidget {
  const _LearnCourseTile({
    required this.track,
    required this.index,
    required this.active,
    required this.completed,
  });

  final RoadmapTrack track;
  final int index;
  final bool active;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = Theme.of(context).textTheme;
    final accent = _levelAccent(context, track.levelNumber);
    final done = track.lessons.where((l) => completed.contains(l.id)).length;
    final progress = const ProgressCalculator().courseProgress(
      track,
      completed,
    );
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: active
              ? palette.accent.withValues(alpha: 0.45)
              : palette.border.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/course/${track.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      track.title.substring(0, 1),
                      style: type.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progress >= 1
                          ? 'COMPLETED'
                          : active
                          ? 'IN FOCUS'
                          : done > 0
                          ? 'IN PROGRESS'
                          : 'COURSE',
                      style: type.labelSmall?.copyWith(
                        color: active ? palette.accent : palette.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    progress >= 1
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_outward_rounded,
                    size: 20,
                    color: progress >= 1 ? palette.success : palette.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                track.title,
                style: type.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                track.tagline,
                style: type.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 22),
              Text(
                '${track.modules.length} modules  ·  ${track.lessons.length} lessons',
                style: type.labelMedium?.copyWith(color: palette.textSecondary),
              ),
              if (done > 0) ...[
                const SizedBox(height: 14),
                AppProgressBar(value: progress, color: accent),
                const SizedBox(height: 8),
                Text(
                  '$done completed · ${(progress * 100).round()}%',
                  style: type.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCluster extends StatelessWidget {
  const _LevelCluster({
    required this.track,
    required this.progress,
    required this.locked,
    required this.completed,
  });

  final RoadmapTrack track;
  final double progress;
  final bool locked;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    final accent = _levelAccent(context, track.levelNumber);
    final calc = const ProgressCalculator();
    final pythonLibraries = track.id == 'track_python'
        ? _pythonLibraries(track)
        : const <LearningModule>[];
    return _NestFrame(
      accent: accent,
      header: InkWell(
        onTap: () => context.push('/course/${track.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LevelBadge(label: 'Course', color: accent),
                  const SizedBox(width: 8),
                  if (locked)
                    StatusPill(
                      label: 'Prereqs',
                      color: context.palette.textMuted,
                    ),
                  if (progress >= 1)
                    StatusPill(
                      label: 'Complete',
                      color: context.palette.success,
                    ),
                  const Spacer(),
                  Text(
                    track.id == 'track_python'
                        ? '${_pythonLanguageCategories(track).length} modules · ${pythonLibraries.length} libraries · ${track.lessons.length} lessons'
                        : '${track.modules.length} modules · ${track.lessons.length} lessons',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(track.tagline, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              AppProgressBar(value: progress, color: accent),
            ],
          ),
        ),
      ),
      children: [
        if (track.id == 'track_python') ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            accent: accent.withValues(alpha: 0.45),
            filled: true,
            onTap: () => context.push('/course/${track.id}'),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Python',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_pythonLanguageCategories(track).length} modules · tap to expand lessons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
          for (var i = 0; i < pythonLibraries.length; i++)
            _DedicatedCourseCard(
              track: track,
              module: pythonLibraries[i],
              index: i + 1,
              accent: accent,
              progress: calc.moduleProgress(pythonLibraries[i], completed),
              done: pythonLibraries[i].lessons
                  .where((l) => completed.contains(l.id))
                  .length,
            ),
        ] else
          for (var i = 0; i < track.modules.length; i++)
            _DedicatedCourseCard(
              track: track,
              module: track.modules[i],
              index: i + 1,
              accent: accent,
              progress: calc.moduleProgress(track.modules[i], completed),
              done: track.modules[i].lessons
                  .where((l) => completed.contains(l.id))
                  .length,
            ),
      ],
    );
  }
}

class _NestFrame extends StatelessWidget {
  const _NestFrame({
    required this.accent,
    required this.header,
    required this.children,
    this.childLabel = 'COURSE MODULES',
  });

  final Color accent;
  final Widget header;
  final List<Widget> children;
  final String childLabel;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.08 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: accent.withValues(alpha: dark ? 0.42 : 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: dark ? 0.22 : 0.16),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl - 1),
              ),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.4)),
              ),
            ),
            child: header,
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 8),
                    child: Text(
                      childLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 10),
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < children.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == children.length - 1 ? 0 : 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 22),
                                        child: Container(
                                          width: 12,
                                          height: 2,
                                          color: accent,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: children[i]),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DedicatedCourseCard extends StatelessWidget {
  const _DedicatedCourseCard({
    required this.track,
    required this.module,
    required this.index,
    required this.accent,
    required this.progress,
    required this.done,
  });

  final RoadmapTrack track;
  final LearningModule module;
  final int index;
  final Color accent;
  final double progress;
  final int done;

  @override
  Widget build(BuildContext context) {
    final minutes = module.lessons.fold<int>(
      0,
      (sum, l) => sum + l.readTimeMinutes,
    );
    return AppCard(
      padding: const EdgeInsets.all(14),
      accent: accent.withValues(alpha: 0.45),
      filled: true,
      onTap: () => context.push('/course/${track.id}/${module.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepIndex(index: index, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (progress >= 1)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: context.palette.success,
                )
              else
                Text(
                  '${module.lessons.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$done/${module.lessons.length} lessons · $minutes min',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                AppProgressBar(value: progress, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndex extends StatelessWidget {
  const _StepIndex({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$index',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color _levelAccent(BuildContext context, int level) {
  final palette = context.palette;
  return level.isEven ? palette.info : palette.violet;
}

const _pythonLibraryIds = {
  'course_py_numpy',
  'course_py_pandas',
  'course_py_matplotlib',
  'course_py_scipy',
  'course_py_seaborn',
  'course_py_plotly',
};

List<LearningModule> _pythonLibraries(RoadmapTrack track) =>
    track.modules.where((m) => _pythonLibraryIds.contains(m.id)).toList();

List<LearningModule> _pythonLanguageCategories(RoadmapTrack track) =>
    track.modules.where((m) => !_pythonLibraryIds.contains(m.id)).toList();

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.trackId, this.moduleId});

  final String trackId;
  final String? moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(curriculumRepositoryProvider).getTrack(trackId);
    final profile = ref.watch(userProfileProvider);
    if (track == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Course missing',
          message: 'This track is not in the catalog.',
        ),
      );
    }
    final module = moduleId == null ? null : track.moduleById(moduleId!);
    if (moduleId != null && module == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Course missing',
          message: 'This dedicated course is not in the catalog.',
        ),
      );
    }
    final calc = const ProgressCalculator();
    final accent = _levelAccent(context, track.levelNumber);
    if (track.id == 'track_python' &&
        (module == null || !_pythonLibraryIds.contains(module.id))) {
      return _PythonCourseScreen(track: track, initialModuleId: module?.id);
    }
    if (module != null) {
      return Scaffold(
        appBar: AppBar(title: Text(module.title)),
        body: ListView(
          padding: pageInsets(context),
          children: [
            PageHeading(
              eyebrow: track.title,
              title: module.title,
              description: module.description,
              icon: Icons.menu_book_outlined,
            ),
            _NestFrame(
              accent: accent,
              childLabel: 'IN THIS COURSE',
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LevelBadge(label: 'Course', color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            track.title,
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${module.lessons.length} lessons · ${module.lessons.fold<int>(0, (s, l) => s + l.readTimeMinutes)} min',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    AppProgressBar(
                      value: calc.moduleProgress(
                        module,
                        profile.completedLessonIds,
                      ),
                      color: accent,
                    ),
                  ],
                ),
              ),
              children: [
                for (final lesson in module.lessons)
                  _LessonTile(
                    lesson: lesson,
                    done: profile.completedLessonIds.contains(lesson.id),
                    accent: accent,
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(track.title)),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: 'Course overview',
            title: track.title,
            description: track.description,
            icon: Icons.menu_book_outlined,
          ),
          if (track.prerequisiteTrackIds.isNotEmpty) ...[
            const Text('Recommended preparation'),
            Wrap(
              spacing: 8,
              children: [
                for (final id in track.prerequisiteTrackIds)
                  TextButton(
                    onPressed: () => context.push('/course/$id'),
                    child: Text(
                      ref
                              .read(curriculumRepositoryProvider)
                              .getTrack(id)
                              ?.title ??
                          id,
                    ),
                  ),
              ],
            ),
          ],
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/labs'),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Experiment lab'),
              ),
              for (final id
                  in track.lessons.expand((l) => l.relatedProjectIds).toSet())
                if (ref.read(catalogRepositoryProvider).project(id) != null)
                  TextButton(
                    onPressed: () => context.push('/project/$id'),
                    child: Text(
                      ref.read(catalogRepositoryProvider).project(id)!.title,
                    ),
                  ),
            ],
          ),
          TextButton.icon(
            onPressed: () => context.push('/interview/${track.id}'),
            icon: const Icon(Icons.question_answer_outlined),
            label: const Text('Interview Prep · practice this course'),
          ),
          _LevelCluster(
            track: track,
            progress: calc.courseProgress(track, profile.completedLessonIds),
            locked: false,
            completed: profile.completedLessonIds,
          ),
        ],
      ),
    );
  }
}

class _PythonCourseScreen extends ConsumerStatefulWidget {
  const _PythonCourseScreen({required this.track, this.initialModuleId});

  final RoadmapTrack track;
  final String? initialModuleId;

  @override
  ConsumerState<_PythonCourseScreen> createState() =>
      _PythonCourseScreenState();
}

class _PythonCourseScreenState extends ConsumerState<_PythonCourseScreen> {
  late final Set<String> _open = {
    if (widget.initialModuleId != null) widget.initialModuleId!,
  };

  void _toggle(String id) {
    setState(() {
      if (_open.contains(id)) {
        _open.remove(id);
      } else {
        _open.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final profile = ref.watch(userProfileProvider);
    final accent = _levelAccent(context, track.levelNumber);
    final categories = _pythonLanguageCategories(track);
    final languageLessons = categories.expand((m) => m.lessons).toList();
    final doneCount = languageLessons
        .where((l) => profile.completedLessonIds.contains(l.id))
        .length;
    final progress = languageLessons.isEmpty
        ? 0.0
        : doneCount / languageLessons.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Python')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: 'The Python course',
            title: track.title,
            description: track.tagline,
            icon: Icons.code_rounded,
          ),
          TextButton.icon(
            onPressed: () => context.push('/interview/${track.id}'),
            icon: const Icon(Icons.question_answer_outlined),
            label: const Text('Interview Prep · practice this course'),
          ),
          const SizedBox(height: 10),
          Text(
            '${categories.length} modules · ${languageLessons.length} lessons',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: progress, color: accent),
          const SizedBox(height: 18),
          Text(
            'Open a module to expand its lessons',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < categories.length; i++)
            _CategoryExpand(
              index: i + 1,
              module: categories[i],
              accent: accent,
              expanded: _open.contains(categories[i].id),
              completed: profile.completedLessonIds,
              onToggle: () => _toggle(categories[i].id),
            ),
        ],
      ),
    );
  }
}

class _CategoryExpand extends StatelessWidget {
  const _CategoryExpand({
    required this.index,
    required this.module,
    required this.accent,
    required this.expanded,
    required this.completed,
    required this.onToggle,
  });

  final int index;
  final LearningModule module;
  final Color accent;
  final bool expanded;
  final Set<String> completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = module.lessons.where((l) => completed.contains(l.id)).length;
    final minutes = module.lessons.fold<int>(
      0,
      (sum, l) => sum + l.readTimeMinutes,
    );
    final progress = const ProgressCalculator().moduleProgress(
      module,
      completed,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        accent: accent.withValues(alpha: expanded ? 0.7 : 0.4),
        filled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  _StepIndex(index: index, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$done/${module.lessons.length} lessons · $minutes min',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppProgressBar(value: progress, color: accent),
            if (expanded) ...[
              const SizedBox(height: 10),
              Text(
                module.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final lesson in module.lessons) ...[
                const SizedBox(height: 8),
                _LessonTile(
                  lesson: lesson,
                  done: completed.contains(lesson.id),
                  accent: accent,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.done,
    required this.accent,
  });

  final Lesson lesson;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      accent: accent.withValues(alpha: 0.45),
      filled: true,
      onTap: () => context.push('/lesson/${lesson.id}'),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.play_circle_outline,
            color: done ? context.palette.success : accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (lesson.subtitle.isNotEmpty)
                  Text(
                    lesson.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                  ),
                Text(
                  '${lesson.readTimeMinutes} min · +${lesson.xpReward} XP',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(tracksProvider);
    final profile = ref.watch(userProfileProvider);
    final ids = ref
        .watch(roadmapGeneratorProvider)
        .generate(
          goal: profile.goal,
          level: profile.skillLevel,
          dailyMinutes: profile.dailyGoalMinutes,
        );
    final tracks = [for (final id in ids) ...catalog.where((t) => t.id == id)];
    final calc = const ProgressCalculator();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roadmap'),
        actions: [
          IconButton(
            tooltip: 'View skill connections',
            onPressed: () => context.push('/skills'),
            icon: const Icon(Icons.hub_outlined),
          ),
        ],
      ),
      body: ListView.builder(
        padding: pageInsets(context),
        itemCount: tracks.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return PageHeading(
              eyebrow: 'Your roadmap',
              title: '${profile.goal.title} path',
              description: 'A clear sequence from your first step to your next milestone.',
              icon: Icons.route_rounded,
            );
          }
          final track = tracks[i - 1];
          final complete = calc.isCourseComplete(
            track,
            profile.completedLessonIds,
          );
          final current = track.id == profile.currentTrackId;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: complete
                            ? context.palette.success
                            : current
                            ? context.palette.accent
                            : context.palette.border,
                      ),
                    ),
                    if (i != tracks.length)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: context.palette.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      onTap: () => context.push('/course/${track.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complete
                                ? 'COMPLETED'
                                : current
                                ? 'YOU ARE HERE'
                                : 'STEP $i',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            track.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            track.tagline,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SkillGraphScreen extends ConsumerWidget {
  const SkillGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(curriculumRepositoryProvider).skillGraph;
    return Scaffold(
      appBar: AppBar(title: const Text('Skill graph')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'The bigger picture',
            title: 'See how skills connect.',
            description: 'Build on what you know. Each foundation prepares you for what comes next.',
            icon: Icons.hub_outlined,
          ),
          const SizedBox(height: 16),
          for (final node in nodes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: node.trackId == null
                    ? null
                    : () => context.push('/course/${node.trackId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (node.trackId != null)
                      TextButton(
                        onPressed: () =>
                            context.push('/interview/${node.trackId}'),
                        child: const Text('Interview Prep'),
                      ),
                    if (node.dependsOn.isNotEmpty)
                      Text(
                        'Builds on ${node.dependsOn.map((id) => nodes.where((n) => n.id == id).firstOrNull?.label ?? id).join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  var _hits = const <SearchHit>[];

  void _run(String value) {
    final catalog = ref.read(catalogRepositoryProvider);
    setState(() {
      _hits = ref
          .read(searchIndexProvider)
          .query(
            rawQuery: value,
            tracks: ref.read(tracksProvider),
            projects: catalog.projects,
            technologies: catalog.technologies,
            interviews: catalog.interviews,
          );
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SearchHit>>{};
    for (final hit in _hits) {
      grouped.putIfAbsent(hit.category, () => []).add(hit);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: pageInsets(context),
        child: Column(
          children: [
            TextField(
              controller: _q,
              autofocus: true,
              onChanged: _run,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'attention, RAG, LoRA, MCP…',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _q.text.isEmpty
                  ? const EmptyState(
                      title: 'What are you curious about?',
                      message: 'Search lessons, projects, libraries, and interview prompts.',
                      icon: Icons.manage_search,
                    )
                  : _hits.isEmpty
                  ? const EmptyState(
                      title: 'No matches',
                      message: 'Try a model name or a concept.',
                    )
                  : ListView(
                      children: [
                        for (final entry in grouped.entries) ...[
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final hit in entry.value)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(hit.title),
                              subtitle: Text(hit.subtitle, maxLines: 2),
                              onTap: () => context.push(hit.route),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref
        .watch(curriculumRepositoryProvider)
        .allLessons
        .reversed
        .take(12)
        .toList();
    final techs = ref.watch(catalogRepositoryProvider).technologies;
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'Follow your curiosity',
            title: 'Find your next idea.',
            description: 'Explore lessons and tools that bring modern AI systems to life.',
            icon: Icons.explore_outlined,
          ),
          Text(
            'Featured lessons',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final lesson in lessons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(lesson.title),
              subtitle: Text(lesson.subtitle, maxLines: 2),
              onTap: () => context.push('/lesson/${lesson.id}'),
            ),
          const SizedBox(height: 12),
          Text(
            'Technology radar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: techs
                .map(
                  (t) => ActionChip(
                    label: Text(t.name),
                    onPressed: () => context.push('/tech/${t.id}'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final curriculum = ref.watch(curriculumRepositoryProvider);
    final catalog = ref.watch(catalogRepositoryProvider);
    final lessons = profile.bookmarkedLessonIds
        .map(curriculum.getLesson)
        .whereType<dynamic>()
        .toList();
    final techs = profile.bookmarkedTechIds
        .map(catalog.technology)
        .whereType<dynamic>()
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: 'Your collection',
            title: 'Keep the good stuff.',
            description:
                '${lessons.length + techs.length} saved lessons and tools, ready when you need them.',
            icon: Icons.bookmarks_outlined,
          ),
          Text('Lessons', style: Theme.of(context).textTheme.titleLarge),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Bookmark a lesson from the reader.'),
            ),
          for (final lesson in lessons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(lesson.title as String),
              onTap: () => context.push('/lesson/${lesson.id}'),
            ),
          const SizedBox(height: 16),
          Text('Technologies', style: Theme.of(context).textTheme.titleLarge),
          if (techs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Save tools from the library.'),
            ),
          for (final tech in techs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tech.name as String),
              onTap: () => context.push('/tech/${tech.id}'),
            ),
        ],
      ),
    );
  }
}
