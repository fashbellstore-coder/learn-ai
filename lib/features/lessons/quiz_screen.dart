import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/content_models.dart';
import '../../shared/widgets/app_primitives.dart';

/// A focused, one-question-at-a-time quiz: pick an answer, see whether it
/// was right straight away, then a results screen with a score, a pass
/// threshold, and a retake option. Works for any lesson's quizQuestions.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const _passThreshold = 70;

  List<QuizQuestion> _questions = const [];
  late List<String?> _selected;
  late List<bool> _answered;
  int _index = 0;
  bool _completed = false;
  int _score = 0;
  int _previousBest = 0;
  String? _boundLessonId;

  void _bind(Lesson lesson) {
    if (_boundLessonId == lesson.id) return;
    _boundLessonId = lesson.id;
    _shuffle(lesson.quizQuestions);
  }

  void _shuffle(List<QuizQuestion> source) {
    final rng = Random();
    _questions = [
      for (final q in source)
        QuizQuestion(
          id: q.id,
          question: q.question,
          type: q.type,
          options: [...q.options]..shuffle(rng),
          codeSnippet: q.codeSnippet,
          codeLanguage: q.codeLanguage,
          explanation: q.explanation,
          hint: q.hint,
          xpReward: q.xpReward,
          difficulty: q.difficulty,
          topic: q.topic,
        ),
    ];
    _selected = List.filled(_questions.length, null);
    _answered = List.filled(_questions.length, false);
    _index = 0;
    _completed = false;
    _score = 0;
  }

  void _finish() {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      final chosen = _selected[i];
      final isRight = _questions[i].options.any(
        (o) => o.id == chosen && o.isCorrect,
      );
      if (isRight) correct++;
    }
    final total = _questions.isEmpty ? 1 : _questions.length;
    final score = ((correct / total) * 100).round();
    _previousBest = ref
        .read(userControllerProvider.notifier)
        .quizScore(widget.lessonId);
    ref
        .read(userControllerProvider.notifier)
        .recordQuizAttempt(
          widget.lessonId,
          score,
          passThreshold: _passThreshold,
        );
    setState(() {
      _score = score;
      _completed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref
        .watch(curriculumRepositoryProvider)
        .getLesson(widget.lessonId);
    if (lesson == null || lesson.quizQuestions.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          title: 'No quiz here',
          message: 'This lesson has no quiz yet.',
        ),
      );
    }
    _bind(lesson);

    if (_completed) return _buildResults(context, lesson);

    final question = _questions[_index];
    final answered = _answered[_index];
    final selected = _selected[_index];
    final isLast = _index >= _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'Knowledge check',
            title: 'Show what you know.',
            description:
                'Choose an answer to see feedback, then move at your own pace.',
            icon: Icons.psychology_outlined,
          ),
          AppProgressBar(value: (_index + 1) / _questions.length),
          const SizedBox(height: 6),
          Text(
            'Question ${_index + 1} of ${_questions.length}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final option in question.options)
            _OptionTile(
              option: option,
              state: !answered
                  ? (selected == option.id
                        ? _OptionState.selected
                        : _OptionState.idle)
                  : (option.isCorrect
                        ? _OptionState.correct
                        : (option.id == selected
                              ? _OptionState.incorrect
                              : _OptionState.idle)),
              onTap: answered
                  ? null
                  : () => setState(() {
                      _selected[_index] = option.id;
                      _answered[_index] = true;
                    }),
            ),
          if (answered) ...[
            const SizedBox(height: 4),
            _ExplanationCard(
              correct: question.options.any(
                (o) => o.id == selected && o.isCorrect,
              ),
              explanation: question.explanation,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_index > 0)
                AppButton(
                  label: 'Previous',
                  tone: AppButtonTone.secondary,
                  onPressed: () => setState(() => _index--),
                ),
              const Spacer(),
              AppButton(
                label: isLast ? 'Finish' : 'Next',
                onPressed: answered
                    ? () {
                        if (isLast) {
                          _finish();
                        } else {
                          setState(() => _index++);
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, Lesson lesson) {
    final palette = context.palette;
    final passed = _score >= _passThreshold;
    final bestScore =
        ref.watch(userControllerProvider).profile.quizScores[widget.lessonId] ??
        _score;
    final isNewBest = _score > _previousBest;
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      final chosen = _selected[i];
      if (_questions[i].options.any((o) => o.id == chosen && o.isCorrect)) {
        correct++;
      }
    }
    final accent = passed ? palette.success : palette.accent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          passed
              ? (isNewBest ? 'New best score' : 'Strong work')
              : 'Almost there',
        ),
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          AppCard(
            accent: accent,
            child: Column(
              children: [
                Icon(
                  passed ? Icons.emoji_events_outlined : Icons.refresh_rounded,
                  size: 48,
                  color: accent,
                ),
                const SizedBox(height: 18),
                Text(
                  '$_score%',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: accent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  passed
                      ? (isNewBest
                            ? 'Passed · new personal best'
                            : 'Passed · best $bestScore%')
                      : 'Need $_passThreshold% to pass · best $bestScore%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _metric(context, 'Best', '$bestScore%')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metric(
                        context,
                        'Correct',
                        '$correct/${_questions.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: passed ? 'Retake' : 'Try again',
                        tone: AppButtonTone.secondary,
                        onPressed: () =>
                            setState(() => _shuffle(lesson.quizQuestions)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Back to lesson',
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Question review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            passed
                ? 'Skim anything that surprised you.'
                : 'Focus on the misses before you retry.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewCard(
                index: i,
                question: _questions[i],
                selectedOptionId: _selected[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

enum _OptionState { idle, selected, correct, incorrect }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.state,
    required this.onTap,
  });

  final QuizOption option;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, border, icon, iconColor) = switch (state) {
      _OptionState.idle => (palette.card, palette.border, null, null),
      _OptionState.selected => (
        palette.accent.withValues(alpha: 0.10),
        palette.accent,
        null,
        null,
      ),
      _OptionState.correct => (
        palette.success.withValues(alpha: 0.12),
        palette.success,
        Icons.check_circle_rounded,
        palette.success,
      ),
      _OptionState.incorrect => (
        palette.danger.withValues(alpha: 0.12),
        palette.danger,
        Icons.cancel_outlined,
        palette.danger,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: border,
                width: state == _OptionState.idle ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: state == _OptionState.idle
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.correct, required this.explanation});
  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = correct ? palette.success : palette.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'Why this works' : 'What to notice',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
  });
  final int index;
  final QuizQuestion question;
  final String? selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = question.options
        .where((o) => o.id == selectedOptionId)
        .toList();
    final correctOption = question.options.firstWhere(
      (o) => o.isCorrect,
      orElse: () => question.options.first,
    );
    final wasCorrect = selected.isNotEmpty && selected.first.isCorrect;
    final statusColor = wasCorrect ? palette.success : palette.danger;

    return AppCard(
      accent: statusColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle_rounded : Icons.cancel_outlined,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                wasCorrect ? 'Correct' : 'Review',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.question,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Your answer: ${selected.isNotEmpty ? selected.first.text : 'No answer selected'}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
          ),
          if (!wasCorrect) ...[
            const SizedBox(height: 4),
            Text(
              'Correct answer: ${correctOption.text}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
