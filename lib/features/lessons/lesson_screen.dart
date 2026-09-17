import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import '../../shared/visualizers/concept_visualizers.dart';
import '../../shared/widgets/app_primitives.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  var _eli5 = true;
  String? _boundLessonId;
  final _drafts = <int, String>{};
  final _outputs = <int, String?>{};
  final _note = TextEditingController();
  final _predictGuess = TextEditingController();
  var _predictRevealed = false;

  static const _debugSlot = 100;
  static const _codingSlot = 101;
  static const _miniSlot = 102;

  void _bindExamples(Lesson lesson) {
    if (_boundLessonId == lesson.id) return;
    _boundLessonId = lesson.id;
    _drafts.clear();
    _outputs.clear();
    _predictGuess.clear();
    _predictRevealed = false;
    final examples = lesson.runnableExamples;
    for (var i = 0; i < examples.length; i++) {
      _drafts[i] = examples[i].code;
    }
    if (lesson.debugChallenge != null) {
      _drafts[_debugSlot] = lesson.debugChallenge!.starterCode;
    }
    if (lesson.codingChallenge != null) {
      _drafts[_codingSlot] = lesson.codingChallenge!.starterCode;
    }
    if (lesson.miniProject != null) {
      _drafts[_miniSlot] = lesson.miniProject!.starterCode;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _predictGuess.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref
        .watch(curriculumRepositoryProvider)
        .getLesson(widget.lessonId);
    final track = ref
        .watch(curriculumRepositoryProvider)
        .trackForLesson(widget.lessonId);
    final profile = ref.watch(userProfileProvider);
    if (lesson == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Lesson missing',
          message: 'Content failed to load.',
        ),
      );
    }
    _bindExamples(lesson);
    final examples = lesson.runnableExamples;
    final done = profile.completedLessonIds.contains(lesson.id);
    final bookmarked = profile.bookmarkedLessonIds.contains(lesson.id);
    final lessons = track?.lessons ?? [lesson];
    final index = lessons.indexWhere((l) => l.id == lesson.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Bookmark',
            onPressed: () => ref
                .read(userControllerProvider.notifier)
                .toggleLessonBookmark(lesson.id),
            icon: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: bookmarked ? context.palette.warning : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          PageHeading(
            eyebrow: track?.title ?? 'Course',
            title: lesson.title,
            description: lesson.subtitle,
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MonoChip(label: '${lesson.readTimeMinutes} min'),
              const SizedBox(width: 6),
              MonoChip(label: '+${lesson.xpReward} XP'),
              const SizedBox(width: 6),
              if (done)
                StatusPill(label: 'Complete', color: context.palette.success),
            ],
          ),
          const SizedBox(height: 18),
          if (lesson.sections.isNotEmpty)
            _friendlySections(lesson.sections)
          else ...[
            _section('Concept', lesson.conceptOverview),
            _section('Why it matters', lesson.whyItMatters),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Simple explanation'),
                  selected: _eli5,
                  onSelected: (_) => setState(() => _eli5 = true),
                ),
                ChoiceChip(
                  label: const Text('Technical deep dive'),
                  selected: !_eli5,
                  onSelected: (_) => setState(() => _eli5 = false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _section(
              _eli5 ? AppStrings.explainEli5 : AppStrings.explainEngineer,
              _eli5 ? lesson.eli5Explanation : lesson.engineerDeepDive,
            ),
            _section('Real-world analogy', lesson.realWorldAnalogy),
            if (lesson.mathFormula != null)
              _section('Mathematics', lesson.mathFormula!),
            if (lesson.mathIntuition != null)
              _section('Intuition', lesson.mathIntuition!),
            if (lesson.visualizerType != VisualizerType.none) ...[
              const SizedBox(height: 8),
              ConceptVisualizer(type: lesson.visualizerType),
            ],
          ],
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Interactive coding',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              examples.length == 1
                  ? 'Run the example. Edit it and run again.'
                  : 'Two examples — run each one. Edit them and experiment.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (var i = 0; i < examples.length; i++) ...[
              const SizedBox(height: 14),
              Text(
                examples[i].title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CodeBlock(
                key: ValueKey('${lesson.id}-ex-$i'),
                code: _drafts[i] ?? examples[i].code,
                languageLabel: examples[i].language.displayName,
                editable: true,
                output: _outputs[i],
                onChanged: (v) => _drafts[i] = v,
                onReset: () => setState(() {
                  _drafts[i] = examples[i].code;
                  _outputs[i] = null;
                }),
                onRun: (code) {
                  _drafts[i] = code;
                  final result = ref
                      .read(codeExecutionProvider)
                      .run(examples[i].language, code);
                  setState(() {
                    if (!result.isSuccess) {
                      _outputs[i] = result.stderr.isEmpty
                          ? 'Error'
                          : result.stderr;
                      return;
                    }
                    final text = result.stdout.replaceAll(RegExp(r'\n$'), '');
                    _outputs[i] = text.isEmpty ? '(no output)' : text;
                  });
                },
              ),
              if (examples[i].explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  examples[i].explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ],
          if (lesson.predictChallenge != null) ...[
            const SizedBox(height: 18),
            _predict(lesson.predictChallenge!),
          ],
          if (lesson.debugChallenge != null)
            _exercise(
              lesson,
              lesson.debugChallenge!,
              _debugSlot,
              lesson.debugChallenge!.starterCode,
            ),
          if (lesson.codingChallenge != null)
            _exercise(
              lesson,
              lesson.codingChallenge!,
              _codingSlot,
              lesson.codingChallenge!.starterCode,
            ),
          if (lesson.miniProject != null)
            _exercise(
              lesson,
              lesson.miniProject!,
              _miniSlot,
              lesson.miniProject!.starterCode,
            ),
          if (lesson.commonMistakes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Common mistakes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final m in lesson.commonMistakes) _bullet(m),
          ],
          if (lesson.interviewQuestion != null) ...[
            const SizedBox(height: 18),
            _interview(lesson.interviewQuestion!),
          ],
          if (lesson.quizQuestions.isNotEmpty) ...[
            const SizedBox(height: 18),
            AppCard(
              onTap: () => context.push('/lesson/${lesson.id}/quiz'),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, color: context.palette.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take the quiz',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lesson.quizQuestions.length} question${lesson.quizQuestions.length == 1 ? '' : 's'} · pass at 70%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
          if (lesson.keyTakeaways.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final t in lesson.keyTakeaways) _bullet(t),
          ],
          const SizedBox(height: 18),
          Text('Notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Capture a highlight…'),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Save note',
            tone: AppButtonTone.secondary,
            onPressed: () async {
              if (_note.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(userControllerProvider.notifier)
                  .addNote(
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                    content: _note.text.trim(),
                  );
              _note.clear();
              messenger.showSnackBar(
                const SnackBar(content: Text('Note saved offline')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (index > 0)
                AppButton(
                  label: 'Prev',
                  tone: AppButtonTone.secondary,
                  onPressed: () => context.pushReplacement(
                    '/lesson/${lessons[index - 1].id}',
                  ),
                ),
              AppButton(
                label: done ? 'Completed' : 'Complete  +${lesson.xpReward} XP',
                onPressed: done
                    ? null
                    : () {
                        final messenger = ScaffoldMessenger.of(context);
                        ref
                            .read(userControllerProvider.notifier)
                            .completeLesson(
                              lesson.id,
                              lesson.xpReward,
                              lesson.readTimeMinutes,
                            );
                        messenger
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.greenAccent,
                                  ).animate().scale(
                                    duration: 300.ms,
                                    curve: Curves.elasticOut,
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Lesson complete — +${lesson.xpReward} XP'),
                                ],
                              ).animate().fadeIn(duration: 200.ms),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                      },
              ),
              if (index >= 0 && index < lessons.length - 1)
                AppButton(
                  label: 'Next',
                  onPressed: () => context.pushReplacement(
                    '/lesson/${lessons[index + 1].id}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _predict(PredictChallenge challenge) {
    final guess = _predictGuess.text.trim();
    final expected = challenge.expectedOutput.trim();
    final matched = _predictRevealed && guess == expected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predict the output',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Read the code. Write what you think it prints. Then reveal.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        CodeBlock(
          code: challenge.code,
          languageLabel: 'Python',
          editable: false,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _predictGuess,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Your predicted output…'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: _predictRevealed ? 'Hide answer' : 'Reveal output',
          tone: AppButtonTone.secondary,
          onPressed: () => setState(() => _predictRevealed = !_predictRevealed),
        ),
        if (_predictRevealed) ...[
          const SizedBox(height: 8),
          Text(
            matched ? 'You predicted it.' : 'Actual output:\n$expected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: matched
                  ? context.palette.success
                  : context.palette.warning,
            ),
          ),
          if (challenge.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              challenge.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ],
    );
  }

  Widget _exercise(
    Lesson lesson,
    CodeExercise exercise,
    int slot,
    String original,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(exercise.prompt, style: Theme.of(context).textTheme.bodySmall),
          if (exercise.hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Hint: ${exercise.hint}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          CodeBlock(
            key: ValueKey('${lesson.id}-ex-$slot'),
            code: _drafts[slot] ?? exercise.starterCode,
            languageLabel: 'Python',
            editable: true,
            output: _outputs[slot],
            onChanged: (v) => _drafts[slot] = v,
            onReset: () => setState(() {
              _drafts[slot] = original;
              _outputs[slot] = null;
            }),
            onRun: (code) {
              _drafts[slot] = code;
              final result = ref
                  .read(codeExecutionProvider)
                  .run(CodeLanguage.python, code);
              setState(() {
                if (!result.isSuccess) {
                  _outputs[slot] = result.stderr.isEmpty
                      ? 'Error'
                      : result.stderr;
                  return;
                }
                final text = result.stdout.replaceAll(RegExp(r'\n$'), '');
                var shown = text.isEmpty ? '(no output)' : text;
                if (exercise.expectedOutput.isNotEmpty &&
                    text.trim() == exercise.expectedOutput.trim()) {
                  shown = '$shown\n\nMatches the expected output.';
                }
                _outputs[slot] = shown;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('·  ', style: Theme.of(context).textTheme.titleMedium),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _interview(InterviewItem item) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interview', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(item.question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(item.modelAnswer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Renders a lesson's friendly, section-based content (the same shape
  /// used by the Python course): a title per section, paragraphs with
  /// **bold** spans and bullet lists, and any ```code``` fences as static
  /// code blocks.
  Widget _friendlySections(List<ContentSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sections) ...[
          if (s.title.isNotEmpty) ...[
            Text(s.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
          ],
          _richBody(s.content),
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  Widget _richBody(String text) {
    final blocks = <Widget>[];
    final fence = RegExp(r'```([a-zA-Z]*)\n([\s\S]*?)```');
    var last = 0;
    for (final m in fence.allMatches(text)) {
      if (m.start > last) blocks.add(_prose(text.substring(last, m.start)));
      final code = (m.group(2) ?? '').trimRight();
      final lang = (m.group(1) ?? '').trim();
      if (code.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CodeBlock(
              code: code,
              languageLabel: lang.isEmpty ? 'Code' : lang,
              editable: false,
            ),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) blocks.add(_prose(text.substring(last)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _prose(String text) {
    final paragraphs = text
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          _paragraph(paragraphs[i]),
          if (i < paragraphs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _paragraph(String paragraph) {
    final lines = paragraph.split('\n');
    final bulletMarker = RegExp(r'^[•-]\s+');
    if (lines.any((line) => bulletMarker.hasMatch(line.trim()))) {
      final heading = lines.first.trim();
      final hasHeading =
          heading.startsWith('**') &&
          heading.endsWith('**') &&
          heading.length > 4;
      final bulletLines = (hasHeading ? lines.skip(1) : lines).where(
        (l) => l.trim().isNotEmpty,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeading) ...[
            _richText(
              heading.substring(2, heading.length - 2),
              Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          for (final line in bulletLines)
            if (bulletMarker.hasMatch(line.trim()))
              _sectionBullet(line.trim().replaceFirst(bulletMarker, ''))
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _richText(line, Theme.of(context).textTheme.bodyLarge),
              ),
        ],
      );
    }
    return _richText(paragraph, Theme.of(context).textTheme.bodyLarge);
  }

  Widget _sectionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.palette.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _richText(text, Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  /// Inline **bold** support without pulling in a markdown package.
  Widget _richText(String text, TextStyle? baseStyle) {
    final spans = <InlineSpan>[];
    final bold = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in bold.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
