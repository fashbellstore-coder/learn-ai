import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/app_primitives.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  CareerGoal? _goal;
  bool _saving = false;
  bool _explore = false;

  Future<void> _finish() async {
    if (_saving || (!_explore && _goal == null)) return;
    setState(() => _saving = true);
    final profile = ref.read(userProfileProvider);
    final goal = _explore ? profile.goal : _goal!;
    final path = ref
        .read(roadmapGeneratorProvider)
        .generate(
          goal: goal,
          level: profile.skillLevel,
          dailyMinutes: profile.dailyGoalMinutes,
        );
    try {
      await ref
          .read(userControllerProvider.notifier)
          .completeOnboarding(
            name: profile.name,
            level: profile.skillLevel,
            goal: goal,
            hasSelectedPath: !_explore,
            dailyMinutes: profile.dailyGoalMinutes,
            firstTrackId: path.firstOrNull ?? profile.currentTrackId,
          );
      if (mounted) context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save your preferences. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: pageInsets(context, top: 12, bottom: 0),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Learn AI', style: type.titleLarge)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: pageInsets(context, top: 16, bottom: 24),
                children: [
                  const PageHeading(
                    eyebrow: 'A starting point, not a commitment',
                    title: 'What would you like to learn?',
                    description: 'Choose a focus for your roadmap, or explore the library first. You can change direction anytime.',
                  ),
                  _choice(
                    title: 'Explore first',
                    subtitle:
                        'Browse the full library and find what interests you.',
                    icon: Icons.explore_outlined,
                    selected: _explore,
                    onTap: () => setState(() {
                      _explore = true;
                      _goal = null;
                    }),
                  ),
                  for (final goal in CareerGoal.values)
                    _choice(
                      title: _goalLabel(goal),
                      subtitle: goal.subtitle,
                      icon: _goalIcon(goal),
                      selected: _goal == goal,
                      onTap: () => setState(() {
                        _goal = goal;
                        _explore = false;
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: pageInsets(context, top: 12, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: _saving
                    ? 'Getting ready…'
                    : _explore
                    ? 'Explore library'
                    : 'Show my path',
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: _saving || (!_explore && _goal == null)
                    ? null
                    : _finish,
              ),
              const SizedBox(height: 8),
              Text(
                'No account needed. Your progress stays on this device.',
                textAlign: TextAlign.center,
                style: type.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          onTap: _saving ? null : onTap,
          accent: selected ? palette.accent : null,
          filled: selected,
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? palette.accent : palette.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: type.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: type.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? palette.accent : palette.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _goalLabel(CareerGoal goal) => switch (goal) {
  CareerGoal.aiEngineer => 'Build AI applications',
  CareerGoal.mlEngineer => 'Machine learning',
  CareerGoal.llmEngineer => 'Large language models',
  CareerGoal.agentEngineer => 'AI agents & automation',
  CareerGoal.cvEngineer => 'Computer vision',
  CareerGoal.nlpEngineer => 'Language & NLP',
  CareerGoal.mlopsEngineer => 'Deploy & operate AI',
  CareerGoal.researcher => 'AI research',
};

IconData _goalIcon(CareerGoal goal) => switch (goal) {
  CareerGoal.aiEngineer => Icons.code_rounded,
  CareerGoal.mlEngineer => Icons.psychology_outlined,
  CareerGoal.llmEngineer => Icons.chat_bubble_outline_rounded,
  CareerGoal.agentEngineer => Icons.hub_outlined,
  CareerGoal.cvEngineer => Icons.visibility_outlined,
  CareerGoal.nlpEngineer => Icons.translate_rounded,
  CareerGoal.mlopsEngineer => Icons.cloud_outlined,
  CareerGoal.researcher => Icons.science_outlined,
};
