import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/app_primitives.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  ProjectTier? _tier;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(catalogRepositoryProvider).projects;
    final projects = all
        .where((p) => _tier == null || p.tier == _tier)
        .toList();
    final done = ref.watch(userProfileProvider).completedProjectIds;
    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Projects')),
        SliverPadding(
          padding: pageInsets(context, bottom: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  eyebrow: 'Built by you',
                  title: 'Make something real.',
                  description: 'Go from understanding a concept to shipping a project you can show.',
                  icon: Icons.handyman_outlined,
                ),
                FeaturePanel(
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 36,
                        color: context.palette.accent,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${done.length} projects completed',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${all.length} guided builds for your portfolio',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All projects'),
                      selected: _tier == null,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _tier = null),
                    ),
                    for (final tier in ProjectTier.values)
                      ChoiceChip(
                        label: Text(
                          tier.name[0].toUpperCase() + tier.name.substring(1),
                        ),
                        selected: _tier == tier,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _tier = tier),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: pageInsets(context, bottom: 100),
          sliver: SliverList.separated(
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = projects[i];
              return AppCard(
                onTap: () => context.push('/project/${p.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: p.tier.name,
                          color: _tierColor(context, p.tier),
                        ),
                        const SizedBox(width: 8),
                        if (done.contains(p.id))
                          StatusPill(
                            label: 'Done',
                            color: context.palette.success,
                          ),
                        const Spacer(),
                        Text(
                          p.estimatedHours,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      p.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Explore project',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: context.palette.accent),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: context.palette.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _tierColor(BuildContext context, ProjectTier tier) {
    final palette = context.palette;
    return switch (tier) {
      ProjectTier.beginner => palette.success,
      ProjectTier.intermediate => palette.info,
      ProjectTier.advanced => palette.warning,
      ProjectTier.expert => palette.danger,
    };
  }
}

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(catalogRepositoryProvider).project(projectId);
    final profile = ref.watch(userProfileProvider);
    if (project == null) {
      return const Scaffold(
        body: EmptyState(title: 'Project missing', message: 'Unknown id.'),
      );
    }
    final done = profile.completedProjectIds.contains(project.id);
    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: '${project.tier.name} · ${project.estimatedHours}',
            title: project.title,
            description: project.objective,
            icon: Icons.layers_outlined,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.techStack.map((t) => MonoChip(label: t)).toList(),
          ),
          const SizedBox(height: 16),
          Text('Architecture', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            child: Text(
              project.architectureDiagram,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 16),
          Text('Requirements', style: Theme.of(context).textTheme.titleLarge),
          ...project.requirements.map(
            (r) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(r),
            ),
          ),
          const SizedBox(height: 8),
          Text('Implementation', style: Theme.of(context).textTheme.titleLarge),
          for (final step in project.steps) ...[
            const SizedBox(height: 10),
            Text(
              '${step.stepNumber}. ${step.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              step.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (step.validationTip.isNotEmpty)
              Text('Verify: ${step.validationTip}'),
            if (step.codeSnippet != null) ...[
              const SizedBox(height: 8),
              CodeBlock(
                code: step.codeSnippet!.code,
                languageLabel: step.codeSnippet!.language.displayName,
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            project.id.startsWith('portfolio_')
                ? 'Your implementation'
                : 'Source',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          CodeBlock(code: project.fullSourceCode, languageLabel: 'Python'),
          const SizedBox(height: 16),
          Text('Testing', style: Theme.of(context).textTheme.titleLarge),
          Text(
            project.testingStrategy,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Deployment', style: Theme.of(context).textTheme.titleLarge),
          Text(
            project.deploymentGuide,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          AppButton(
            expand: true,
            label: done
                ? 'In your portfolio'
                : 'Mark complete  +${project.xpReward} XP',
            onPressed: done
                ? null
                : () => ref
                      .read(userControllerProvider.notifier)
                      .completeProject(project.id, project.xpReward),
          ),
        ],
      ),
    );
  }
}
