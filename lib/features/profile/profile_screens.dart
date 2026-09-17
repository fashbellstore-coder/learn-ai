import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/app_primitives.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userControllerProvider);
    final profile = session.profile;
    final tracks = ref.watch(tracksProvider);
    final catalog = ref.watch(catalogRepositoryProvider);
    final lessons = tracks
        .expand((t) => t.lessons)
        .where((l) => profile.completedLessonIds.contains(l.id))
        .length;
    final courses = tracks
        .where(
          (t) =>
              t.lessons.isNotEmpty &&
              t.lessons.every((l) => profile.completedLessonIds.contains(l.id)),
        )
        .length;
    final projects = catalog.projects
        .where((p) => profile.completedProjectIds.contains(p.id))
        .length;
    final inProgress = tracks.where((t) {
      final done = t.lessons
          .where((l) => profile.completedLessonIds.contains(l.id))
          .length;
      return done > 0 && done < t.lessons.length;
    }).toList();
    final saved =
        tracks
            .expand((t) => t.lessons)
            .where((l) => profile.bookmarkedLessonIds.contains(l.id))
            .length +
        catalog.technologies
            .where((t) => profile.bookmarkedTechIds.contains(t.id))
            .length;
    final name = profile.name.trim().isEmpty ? 'Learner' : profile.name.trim();
    final today = DateTime.now().toIso8601String().split('T').first;
    final minutes = profile.lastActiveDate == today
        ? profile.dailyMinutesSpent
        : 0;
    final palette = context.palette;
    final type = Theme.of(context).textTheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Profile'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        SliverPadding(
          padding: pageInsets(context, bottom: 40),
          sliver: SliverList.list(
            children: [
              FeaturePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: palette.accent.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            name.characters.first.toUpperCase(),
                            style: type.headlineMedium?.copyWith(
                              color: palette.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: type.headlineMedium),
                              const SizedBox(height: 4),
                              Text(
                                'Your learning record',
                                style: type.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          label: '${profile.xp} total XP',
                          color: palette.accent,
                          icon: Icons.bolt_rounded,
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Your progress'),
              const SizedBox(height: 12),
              _ProfileGrid(
                children: [
                  _ProgressMetric(
                    value: lessons,
                    label: 'Lessons',
                    icon: Icons.menu_book_outlined,
                  ),
                  _ProgressMetric(
                    value: courses,
                    label: 'Courses',
                    icon: Icons.school_outlined,
                  ),
                  _ProgressMetric(
                    value: projects,
                    label: 'Projects',
                    icon: Icons.layers_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Completed in the current library', style: type.bodySmall),
              const SizedBox(height: 20),
              Text('Skill evidence', style: type.titleLarge),
              const Text(
                'Quiz coverage is the share of course quizzes passed (70%+). Reading progress and self-reported projects are separate evidence, not verified engineering mastery.',
              ),
              const SizedBox(height: 8),
              for (final track in tracks.where(
                (t) => t.lessons.any(
                  (l) =>
                      profile.completedLessonIds.contains(l.id) ||
                      profile.quizScores.containsKey(l.id),
                ),
              ))
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title, style: type.titleMedium),
                      Builder(
                        builder: (context) {
                          final assessed = track.lessons
                              .where((l) => l.quizQuestions.isNotEmpty)
                              .toList();
                          final passed = assessed
                              .where(
                                (l) => (profile.quizScores[l.id] ?? 0) >= 70,
                              )
                              .length;
                          final related = track.lessons
                              .expand((l) => l.relatedProjectIds)
                              .toSet();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$passed / ${assessed.length} lesson quizzes passed',
                              ),
                              LinearProgressIndicator(
                                value: assessed.isEmpty
                                    ? 0
                                    : passed / assessed.length,
                              ),
                              Text(
                                '${related.where(profile.completedProjectIds.contains).length} / ${related.length} linked projects marked complete',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              SectionHeader(
                title: 'Your focus',
                action: 'Change',
                onAction: () => context.push('/career'),
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: () => context.push('/career'),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: palette.accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.hasSelectedPath
                                ? profile.goal.title
                                : 'Explore all courses',
                            style: type.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.hasSelectedPath ? profile.goal.subtitle : 'Follow your curiosity, or choose a path anytime.',
                            style: type.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today’s learning', style: type.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '$minutes of ${profile.dailyGoalMinutes} minutes',
                      style: type.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    AppProgressBar(
                      value: profile.dailyGoalMinutes > 0
                          ? minutes / profile.dailyGoalMinutes
                          : 0,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('Adjust daily goal'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Keep going',
                action: 'Learn',
                onAction: () => context.go('/learn'),
              ),
              const SizedBox(height: 8),
              if (inProgress.isEmpty)
                AppCard(
                  onTap: () => context.go('/learn'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lessons == 0
                            ? 'Your first lesson starts something.'
                            : 'Ready for your next course?',
                        style: type.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Browse your courses and choose a place to begin.',
                        style: type.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Browse courses →',
                        style: type.labelLarge?.copyWith(color: palette.accent),
                      ),
                    ],
                  ),
                ),
              for (final track in inProgress.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context.push('/course/${track.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, style: type.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${track.lessons.where((l) => profile.completedLessonIds.contains(l.id)).length} of ${track.lessons.length} lessons complete',
                          style: type.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AppProgressBar(
                          value:
                              track.lessons
                                  .where(
                                    (l) => profile.completedLessonIds.contains(
                                      l.id,
                                    ),
                                  )
                                  .length /
                              track.lessons.length,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Saved for later'),
              const SizedBox(height: 12),
              _ProfileGrid(
                columns: 2,
                children: [
                  _CollectionLink(
                    title: 'Bookmarks',
                    detail: '$saved saved',
                    icon: Icons.bookmarks_outlined,
                    onTap: () => context.push('/bookmarks'),
                  ),
                  _CollectionLink(
                    title: 'Notes',
                    detail: '${session.notes.length} saved',
                    icon: Icons.notes_rounded,
                    onTap: () => context.push('/notes'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Milestones'),
              const SizedBox(height: 6),
              Text(
                'Small wins, built from your actual progress.',
                style: type.bodySmall,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _Milestone(
                      title: 'First step',
                      detail: 'Complete your first lesson',
                      achieved: lessons > 0,
                    ),
                    const Divider(height: 24),
                    _Milestone(
                      title: 'Finding your rhythm',
                      detail: '${lessons.clamp(0, 10)} of 10 lessons complete',
                      achieved: lessons >= 10,
                    ),
                    const Divider(height: 24),
                    _Milestone(
                      title: 'A course of your own',
                      detail: 'Complete every lesson in one course',
                      achieved: courses > 0,
                    ),
                    const Divider(height: 24),
                    _Milestone(
                      title: 'Made it real',
                      detail: 'Complete your first project',
                      achieved: projects > 0,
                    ),
                  ],
                ),
              ),
              if (profile.badges.any((b) => b.isUnlocked)) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Earned badges'),
                const SizedBox(height: 10),
                for (final badge in profile.badges.where((b) => b.isUnlocked))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.verified_outlined,
                          color: palette.success,
                        ),
                        title: Text(badge.title),
                        subtitle: Text(badge.description),
                      ),
                    ),
                  ),
              ],
              if (profile.earnedCertificates.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Certificates'),
                const SizedBox(height: 10),
                for (final cert in profile.earnedCertificates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: palette.violet,
                          ),
                          const SizedBox(height: 12),
                          Text(cert.title, style: type.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            '${cert.track} · ${cert.issueDate} · ${cert.grade}',
                            style: type.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'ID ${cert.id}',
                            style: type.labelSmall,
                          ),
                          if (cert.skillsEarned.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final skill in cert.skillsEarned)
                                  MonoChip(label: skill),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                'Saved on this device. Cloud syncing is not available yet.',
                textAlign: TextAlign.center,
                style: type.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({required this.children, this.columns = 3});
  final List<Widget> children;
  final int columns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count =
          constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 19
          ? 1
          : columns;
      return Column(
        children: [
          for (var i = 0; i < children.length; i += count)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + count < children.length ? 10 : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < count; c++) ...[
                      if (c > 0) const SizedBox(width: 10),
                      Expanded(
                        child: i + c < children.length
                            ? children[i + c]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
  final int value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label completed',
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.palette.accent, size: 21),
          const SizedBox(height: 12),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _CollectionLink extends StatelessWidget {
  const _CollectionLink({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.accent),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.title,
    required this.detail,
    required this.achieved,
  });
  final String title;
  final String detail;
  final bool achieved;
  @override
  Widget build(BuildContext context) => Semantics(
    label: achieved ? 'Achieved' : 'Not yet achieved',
    child: Row(
      children: [
        Icon(
          achieved ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: achieved ? context.palette.success : context.palette.textMuted,
          size: 24,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(userControllerProvider).notes;
    final curriculum = ref.watch(curriculumRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'In your own words',
            title: 'Keep the ideas that click.',
            description: 'Revisit the notes you save while learning.',
            icon: Icons.notes_rounded,
          ),
          if (notes.isEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your notebook starts with a lesson.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the note field in any lesson to save a thought or explanation here.',
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Explore lessons',
                    onPressed: () => context.go('/learn'),
                  ),
                ],
              ),
            ),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    scrollable: true,
                    title: Text(note.lessonTitle),
                    content: SelectableText(note.content),
                    actions: [
                      if (curriculum.getLesson(note.lessonId) != null)
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.push('/lesson/${note.lessonId}');
                          },
                          child: const Text('Open lesson'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.lessonTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Read note →',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: context.palette.accent),
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'Make it yours',
            title: 'Your learning rhythm.',
            description: 'Choose the look and daily pace that work for you.',
            icon: Icons.tune_rounded,
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Edit profile'),
            subtitle: const Text('Optional name and email'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile/edit'),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('A quieter canvas for focused learning'),
            value: session.isDark,
            onChanged: (v) =>
                ref.read(userControllerProvider.notifier).setTheme(v),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily goal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: ValueKey(session.profile.dailyGoalMinutes),
                  initialValue: session.profile.dailyGoalMinutes,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Learning time per day',
                  ),
                  items: _dailyGoalOptions(session.profile.dailyGoalMinutes)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_formatDailyGoal(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(userControllerProvider.notifier).setDailyGoal(v);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(
              'Your learning progress and preferences are stored on this device.',
            ),
          ),
          const ListTile(
            title: Text('Security'),
            subtitle: Text(
              'This version uses a local profile. Cloud account sign-in is not available yet.',
            ),
          ),
        ],
      ),
    );
  }
}

List<int> _dailyGoalOptions(int current) {
  const presets = [10, 20, 30, 45, 60, 90, 120, 180, 240, 300, 360];
  return {...presets, current}.toList()..sort();
}

String _formatDailyGoal(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return hours == 1 ? '1 hour' : '$hours hours';
  return '${hours}h ${rest}m';
}

class CareerScreen extends ConsumerWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final path = ref
        .watch(roadmapGeneratorProvider)
        .generate(
          goal: profile.goal,
          level: profile.skillLevel,
          dailyMinutes: profile.dailyGoalMinutes,
        );
    final tracks = ref.watch(tracksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Career mode')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: 'Your destination',
            title: profile.goal.title,
            description: profile.goal.subtitle,
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 16),
          Text('Change target', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final goal in CareerGoal.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                accent: goal == profile.goal ? context.palette.accent : null,
                onTap: () =>
                    ref.read(userControllerProvider.notifier).setGoal(goal),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            goal.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      goal == profile.goal
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: goal == profile.goal
                          ? context.palette.accent
                          : context.palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Recommended sequence',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final id in path)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: context.palette.accent.withValues(alpha: 0.1),
                child: Text(
                  '${path.indexOf(id) + 1}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              title: Text(
                tracks.where((t) => t.id == id).firstOrNull?.title ?? id,
              ),
              onTap: () => context.push('/course/$id'),
            ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Interview lab',
            onPressed: () => context.push('/interview'),
          ),
        ],
      ),
    );
  }
}
