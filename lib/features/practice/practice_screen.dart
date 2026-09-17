import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_extras.dart';
import '../../core/utils/learning_math.dart';
import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/app_primitives.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late List<QuizQuestion> _queue;
  var _index = 0;
  final _picked = <String>{};
  var _revealed = false;
  var _score = 0;

  @override
  void initState() {
    super.initState();
    final fromLessons = ref
        .read(curriculumRepositoryProvider)
        .allLessons
        .expand((l) => l.quizQuestions);
    final extras = ref.read(catalogRepositoryProvider).extraDrills;
    _queue = [...fromLessons, ...extras];
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          title: 'No drills',
          message: 'Quizzes appear as lessons are authored.',
        ),
      );
    }
    final q = _queue[_index % _queue.length];
    final result = _revealed ? const QuizScorer().score(q, _picked) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          TextButton(
            onPressed: () => context.push('/interview'),
            child: const Text('Interview'),
          ),
        ],
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const PageHeading(
            eyebrow: 'The practice studio',
            title: 'Turn knowledge into instinct.',
            description:
                'Small challenges. Clear feedback. Lasting understanding.',
            icon: Icons.bolt_rounded,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              StatusPill(
                label: 'Question ${_index + 1}',
                color: context.palette.accent,
              ),
              StatusPill(
                label: '$_score session XP',
                color: context.palette.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: q.difficulty.name.toUpperCase(),
                  color: context.palette.violet,
                ),
                const SizedBox(height: 10),
                Text(
                  q.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  q.type == QuizQuestionType.multipleChoice
                      ? 'Select all answers that apply.'
                      : 'Choose one answer.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final opt in q.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      accent: _revealed && opt.isCorrect
                          ? context.palette.success
                          : _picked.contains(opt.id)
                          ? context.palette.accent
                          : null,
                      filled: _picked.contains(opt.id),
                      child: CheckboxListTile(
                        value: _picked.contains(opt.id),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        checkboxShape: q.type == QuizQuestionType.multipleChoice
                            ? null
                            : const CircleBorder(),
                        title: Text(
                          opt.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onChanged: _revealed
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  if (q.type != QuizQuestionType.multipleChoice) {
                                    _picked.clear();
                                  }
                                  _picked.add(opt.id);
                                } else {
                                  _picked.remove(opt.id);
                                }
                              }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (result != null)
            AppCard(
              accent: result.isCorrect
                  ? context.palette.success
                  : context.palette.warning,
              child: Text(
                result.isCorrect ? 'Correct. ${q.explanation}' : q.explanation,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 16),
          AppButton(
            expand: true,
            label: _revealed ? 'Next question' : 'Check answer',
            icon: _revealed ? Icons.arrow_forward_rounded : Icons.check_rounded,
            onPressed: !_revealed && _picked.isEmpty
                ? null
                : () {
                    if (!_revealed) {
                      final scored = const QuizScorer().score(q, _picked);
                      setState(() {
                        _revealed = true;
                        if (scored.isCorrect) _score += scored.awardedXp;
                      });
                    } else {
                      setState(() {
                        _revealed = false;
                        _picked.clear();
                        _index++;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }
}
