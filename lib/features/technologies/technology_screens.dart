import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/app_primitives.dart';

class TechnologiesScreen extends ConsumerWidget {
  const TechnologiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(catalogRepositoryProvider).technologies;
    final grouped = <TechCategory, List<dynamic>>{};
    for (final t in items) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Technology library')),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'The AI toolkit',
            title: 'Know your tools.',
            description: 'Understand what each technology does, when to use it, and how to get started.',
            icon: Icons.widgets_outlined,
          ),
          for (final entry in grouped.entries) ...[
            Text(
              entry.key.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final tech in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.push('/tech/${tech.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tech.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 18,
                            color: context.palette.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tech.tagline,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class TechnologyDetailScreen extends ConsumerWidget {
  const TechnologyDetailScreen({super.key, required this.techId});
  final String techId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tech = ref.watch(catalogRepositoryProvider).technology(techId);
    final saved = ref
        .watch(userProfileProvider)
        .bookmarkedTechIds
        .contains(techId);
    if (tech == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Unknown technology',
          message: 'Not in the library.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tech.name),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove bookmark' : 'Save technology',
            onPressed: () => ref
                .read(userControllerProvider.notifier)
                .toggleTechBookmark(tech.id),
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? context.palette.warning : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: tech.category.title,
            title: tech.name,
            description: tech.tagline,
            icon: Icons.widgets_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${tech.lastUpdated} · ${tech.versionLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _h(context, 'What it is', tech.whatItIs),
          _h(context, 'Why it exists', tech.whyItExists),
          _list(context, 'When to use', tech.whenToUse),
          _list(context, 'When not to use', tech.whenNotToUse),
          Text('Install', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          CodeBlock(code: tech.installationCommand, languageLabel: 'bash'),
          const SizedBox(height: 12),
          Text(
            'Minimal example',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          CodeBlock(code: tech.minimalExampleCode, languageLabel: 'python'),
          const SizedBox(height: 12),
          Text('Advanced', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          CodeBlock(code: tech.advancedExampleCode, languageLabel: 'python'),
          const SizedBox(height: 12),
          _h(context, 'Architecture', tech.architectureOverview),
          _list(context, 'Pros', tech.pros),
          _list(context, 'Cons', tech.cons),
          _list(context, 'Alternatives', tech.alternatives),
          if (tech.relatedProjects.isNotEmpty) ...[
            Text('Projects', style: Theme.of(context).textTheme.titleLarge),
            ...tech.relatedProjects.map(
              (id) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(id),
                onTap: () => context.push('/project/$id'),
              ),
            ),
          ],
          Text(
            'Docs  ${tech.officialDocsUrl}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _h(BuildContext context, String t, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(b, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, String t, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: Theme.of(context).textTheme.titleLarge),
          ...items.map(
            (e) => Text('· $e', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
