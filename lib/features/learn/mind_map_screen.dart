import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/content/learning_paths.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/content_models.dart';

class CourseMindMapScreen extends ConsumerStatefulWidget {
  const CourseMindMapScreen({super.key});

  @override
  ConsumerState<CourseMindMapScreen> createState() =>
      _CourseMindMapScreenState();
}

class _CourseMindMapScreenState extends ConsumerState<CourseMindMapScreen> {
  LearningPath? _path;
  final Set<String> _openTracks = {};
  final Set<String> _openModules = {};

  void _toggleTrack(String id) {
    setState(() {
      if (!_openTracks.remove(id)) _openTracks.add(id);
    });
  }

  void _toggleModule(String id) {
    setState(() {
      if (!_openModules.remove(id)) _openModules.add(id);
    });
  }

  void _collapseAll() {
    setState(() {
      _openTracks.clear();
      _openModules.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTracks = ref.watch(tracksProvider);
    final tracks = _path == null
        ? allTracks
        : [
            for (final id in _path!.courseIds)
              ...allTracks.where((t) => t.id == id),
          ];
    final completed = ref.watch(userProfileProvider).completedLessonIds;
    final moduleCount = tracks.fold<int>(
      0,
      (total, track) => total + track.modules.length,
    );
    final lessonCount = tracks.fold<int>(
      0,
      (total, track) => total + track.lessons.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course map'),
        actions: [
          if (_openTracks.isNotEmpty)
            TextButton.icon(
              onPressed: _collapseAll,
              icon: const Icon(Icons.unfold_less_rounded, size: 18),
              label: const Text('Collapse'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width >= 700 ? 32 : 16,
          12,
          MediaQuery.sizeOf(context).width >= 700 ? 32 : 16,
          40,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<LearningPath>(
                    isExpanded: true,
                    initialValue: _path,
                    decoration: const InputDecoration(
                      labelText: 'Career track',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<LearningPath>(
                        value: null,
                        child: Text('All courses'),
                      ),
                      for (final path in learningPaths)
                        DropdownMenuItem(
                          value: path,
                          child: Text(
                            path.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _path = value),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _path?.description ?? 'Explore shared courses and independent specializations. No global level sequence.',
                  ),
                  const SizedBox(height: 16),
                  _MapRoot(
                    courses: tracks.length,
                    modules: moduleCount,
                    lessons: lessonCount,
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < tracks.length; i++)
                    _CourseBranch(
                      index: i + 1,
                      track: tracks[i],
                      expanded: _openTracks.contains(tracks[i].id),
                      openModules: _openModules,
                      completed: completed,
                      isLast: i == tracks.length - 1,
                      onToggle: () => _toggleTrack(tracks[i].id),
                      onToggleModule: _toggleModule,
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

class _MapRoot extends StatelessWidget {
  const _MapRoot({
    required this.courses,
    required this.modules,
    required this.lessons,
  });

  final int courses;
  final int modules;
  final int lessons;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: context.isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: palette.accent.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.account_tree_rounded, color: palette.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn AI',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$courses courses  ·  $modules modules  ·  $lessons lessons',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open a course, then a module, to reach its lessons.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseBranch extends StatelessWidget {
  const _CourseBranch({
    required this.index,
    required this.track,
    required this.expanded,
    required this.openModules,
    required this.completed,
    required this.isLast,
    required this.onToggle,
    required this.onToggleModule,
  });

  final int index;
  final RoadmapTrack track;
  final bool expanded;
  final Set<String> openModules;
  final Set<String> completed;
  final bool isLast;
  final VoidCallback onToggle;
  final ValueChanged<String> onToggleModule;

  @override
  Widget build(BuildContext context) {
    final accent = _trackColor(track);
    final done = track.lessons.where((lesson) => completed.contains(lesson.id));
    return _TreeBranch(
      lineColor: accent,
      isLast: isLast,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpandableNode(
              key: ValueKey('course-${track.id}'),
              accent: accent,
              expanded: expanded,
              onTap: onToggle,
              leading: Text(
                track.title.substring(0, 1),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: accent, fontWeight: FontWeight.w800),
              ),
              title: track.title,
              subtitle:
                  '${track.modules.length} modules · ${track.lessons.length} lessons'
                  '${done.isEmpty ? '' : ' · ${done.length} done'}',
              trailingAction: IconButton(
                tooltip: 'Open ${track.title} course',
                onPressed: () => context.push('/course/${track.id}'),
                icon: const Icon(Icons.arrow_outward_rounded, size: 19),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Column(
                  children: [
                    for (var i = 0; i < track.modules.length; i++)
                      _ModuleBranch(
                        module: track.modules[i],
                        accent: accent,
                        expanded: openModules.contains(track.modules[i].id),
                        completed: completed,
                        isLast: i == track.modules.length - 1,
                        onToggle: () => onToggleModule(track.modules[i].id),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleBranch extends StatelessWidget {
  const _ModuleBranch({
    required this.module,
    required this.accent,
    required this.expanded,
    required this.completed,
    required this.isLast,
    required this.onToggle,
  });

  final LearningModule module;
  final Color accent;
  final bool expanded;
  final Set<String> completed;
  final bool isLast;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = module.lessons
        .where((lesson) => completed.contains(lesson.id))
        .length;
    return _TreeBranch(
      lineColor: accent.withValues(alpha: 0.72),
      isLast: isLast,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpandableNode(
              key: ValueKey('module-${module.id}'),
              accent: accent,
              expanded: expanded,
              compact: true,
              onTap: onToggle,
              leading: Icon(
                Icons.folder_copy_outlined,
                color: accent,
                size: 19,
              ),
              title: module.title,
              subtitle:
                  '${module.lessons.length} lessons${done == 0 ? '' : ' · $done done'}',
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Column(
                  children: [
                    for (var i = 0; i < module.lessons.length; i++)
                      _LessonBranch(
                        lesson: module.lessons[i],
                        accent: accent,
                        completed: completed.contains(module.lessons[i].id),
                        isLast: i == module.lessons.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonBranch extends StatelessWidget {
  const _LessonBranch({
    required this.lesson,
    required this.accent,
    required this.completed,
    required this.isLast,
  });

  final Lesson lesson;
  final Color accent;
  final bool completed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _TreeBranch(
      lineColor: accent.withValues(alpha: 0.5),
      isLast: isLast,
      child: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Material(
          color: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border.withValues(alpha: 0.6)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/lesson/${lesson.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    color: completed ? palette.success : accent,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lesson.readTimeMinutes} min',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableNode extends StatelessWidget {
  const _ExpandableNode({
    super.key,
    required this.accent,
    required this.expanded,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailingAction,
    this.compact = false,
  });

  final Color accent;
  final bool expanded;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailingAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: expanded
          ? accent.withValues(alpha: context.isDark ? 0.14 : 0.08)
          : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 19),
        side: BorderSide(
          color: expanded
              ? accent.withValues(alpha: 0.62)
              : palette.border.withValues(alpha: 0.68),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 10 : 13,
            6,
            compact ? 10 : 13,
          ),
          child: Row(
            children: [
              SizedBox(
                width: compact ? 26 : 34,
                child: Center(child: leading),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleSmall
                                  : Theme.of(context).textTheme.titleMedium)
                              ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              ?trailingAction,
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: accent,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeBranch extends StatelessWidget {
  const _TreeBranch({
    required this.lineColor,
    required this.isLast,
    required this.child,
  });

  final Color lineColor;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BranchPainter(color: lineColor, isLast: isLast),
      child: Padding(padding: const EdgeInsets.only(left: 22), child: child),
    );
  }
}

class _BranchPainter extends CustomPainter {
  const _BranchPainter({required this.color, required this.isLast});

  final Color color;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const x = 9.0;
    const elbowY = 30.0;
    canvas.drawLine(
      const Offset(x, 0),
      Offset(x, isLast ? elbowY : size.height),
      paint,
    );
    canvas.drawLine(const Offset(x, elbowY), const Offset(22, elbowY), paint);
    canvas.drawCircle(
      const Offset(22, elbowY),
      2.2,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BranchPainter oldDelegate) {
    return color != oldDelegate.color || isLast != oldDelegate.isLast;
  }
}

Color _trackColor(RoadmapTrack track) {
  final hex = track.colorHex.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16);
  return value == null ? const Color(0xFF2979FF) : Color(0xFF000000 | value);
}
