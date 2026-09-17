import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/models/interview_models.dart';
import '../../shared/widgets/app_primitives.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key, this.trackId});
  final String? trackId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(tracksProvider);
    if (trackId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Interview Prep')),
        body: ListView(
          padding: pageInsets(context),
          children: [
            const Text(
              'Practice your next interview',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Curated questions, reference answers and fixed follow-ups. Everything runs locally. No LLM or API calls.',
            ),
            const SizedBox(height: 20),
            for (final c in courses)
              Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle: const Text(
                    'Practice · Interview · Rapid Fire · Scenarios · Mock',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/interview/${c.id}'),
                ),
              ),
          ],
        ),
      );
    }
    final course = courses.where((c) => c.id == trackId).firstOrNull;
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Interview Prep')),
        body: const Center(child: Text('Course not found.')),
      );
    }
    final bank = ref.watch(interviewBankProvider(trackId!));
    return bank.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('${course.title} Interview Prep')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Interview Prep')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The local question bank could not be loaded.'),
              TextButton(
                onPressed: () {
                  ref.read(interviewPrepRepositoryProvider).retry(trackId!);
                  ref.invalidate(interviewBankProvider(trackId!));
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (value) => _InterviewExperience(
        key: ValueKey(trackId),
        bank: value,
        title: course.title,
      ),
    );
  }
}

class _InterviewExperience extends ConsumerStatefulWidget {
  const _InterviewExperience({
    super.key,
    required this.bank,
    required this.title,
  });
  final InterviewBank bank;
  final String title;
  @override
  ConsumerState<_InterviewExperience> createState() =>
      _InterviewExperienceState();
}

class _InterviewExperienceState extends ConsumerState<_InterviewExperience> {
  InterviewMode? _mode;
  List<PrepQuestion> _pool = [];
  int _index = 0, _questionStart = 0;
  final _trail = <String>[];
  final _responses = <String, PrepResponse>{};
  final _watch = Stopwatch();
  Timer? _ticker;
  bool _finished = false, _paused = false, _saving = false;
  Map<String, dynamic>? _summary;
  String? _saveError;
  List<Map<String, dynamic>> _history = [];
  String get _storageKey =>
      'learn_ai.interview_prep.v1.${widget.bank.courseId}';
  PrepQuestion get _question =>
      _trail.isEmpty ? _pool[_index] : widget.bank.question(_trail.last);
  PrepResponse _response(PrepQuestion q) => _responses.putIfAbsent(
    q.id,
    () => PrepResponse()
      ..order = q.choices.map((c) => c.id).toList()
      ..revealed = _mode == InterviewMode.practice,
  );
  String _time(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_storageKey);
      if (raw != null) {
        _history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {
      _history = [];
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  void _start(InterviewMode mode) {
    _ticker?.cancel();
    setState(() {
      _mode = mode;
      _pool = widget.bank.session(mode);
      _index = 0;
      _trail.clear();
      _responses.clear();
      _finished = false;
      _paused = false;
      _summary = null;
      _saveError = null;
      _questionStart = 0;
      _watch
        ..reset()
        ..start();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) setState(() {});
    });
  }

  void _reveal({bool skip = false}) {
    final q = _question;
    final r = _response(q);
    setState(() {
      r.seconds = _watch.elapsed.inSeconds - _questionStart;
      r.revealed = true;
      r.submitted = !skip;
      if (q.objective && !skip) r.correct = scoreInterviewAnswer(q, r);
    });
  }

  void _next() {
    if (_index == _pool.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _trail.clear();
      _questionStart = _watch.elapsed.inSeconds;
    });
  }

  Future<void> _finish() async {
    if (_saving || _finished) return;
    _watch.stop();
    _ticker?.cancel();
    var correct = 0, attempted = 0, covered = 0, possible = 0, selfCount = 0;
    final weak = <String>{};
    for (final entry in _responses.entries) {
      final q = widget.bank.question(entry.key);
      final r = entry.value;
      if (!r.submitted) continue;
      if (q.objective) {
        attempted++;
        if (r.correct == true) {
          correct++;
        } else {
          weak.add(q.category);
        }
      } else {
        selfCount++;
        covered += r.points.length;
        possible += q.keyPoints.length;
        if (r.points.length < q.keyPoints.length) weak.add(q.category);
      }
    }
    final summary = <String, dynamic>{
      'mode': _mode!.name,
      'modeLabel': _mode!.label,
      'date': DateTime.now().toIso8601String(),
      'correct': correct,
      'attempted': attempted,
      'covered': covered,
      'possible': possible,
      'selfCount': selfCount,
      'seconds': _watch.elapsed.inSeconds,
      'weak': weak.toList(),
      'completed': _pool
          .where((q) => _responses[q.id]?.revealed == true)
          .length,
      'total': _pool.length,
    };
    setState(() {
      _summary = summary;
      _finished = true;
      _saving = true;
    });
    final history = [summary, ..._history].take(10).toList();
    try {
      final saved = await ref
          .read(sharedPreferencesProvider)
          .setString(_storageKey, jsonEncode(history));
      if (!saved) throw StateError('Save failed');
      if (mounted) setState(() => _history = history);
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'This result could not be saved. It remains visible below.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _button(String text, VoidCallback? action) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: FilledButton(onPressed: action, child: Text(text)),
  );
  Widget _layout(List<Widget> children) => ListView(
    padding: pageInsets(context),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Interview Prep')),
        body: _layout([
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Pick a format and practice at your own pace. Objective questions use fixed answer keys. Typed answers are never automatically graded.',
          ),
          const SizedBox(height: 12),
          for (final mode in InterviewMode.values)
            Card(
              child: ListTile(
                title: Text(mode.label),
                subtitle: Text(
                  '${mode.description}\n${widget.bank.session(mode).length} questions',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.play_arrow),
                onTap: () => _start(mode),
              ),
            ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent local sessions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final h in _history.take(3))
              ListTile(
                title: Text(
                  '${h['modeLabel'] ?? h['mode']} · ${h['completed']}/${h['total']} reviewed',
                ),
                subtitle: Text(
                  'Objective: ${h['correct']}/${h['attempted']} · self-reported points: ${h['covered']}/${h['possible']}',
                ),
              ),
          ],
        ]),
      );
    }
    if (_finished) {
      final s = _summary!;
      return Scaffold(
        appBar: AppBar(title: const Text('Session results')),
        body: _layout([
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${s['completed']} of ${s['total']} main questions reviewed · ${_time(s['seconds'] as int)}',
          ),
          const SizedBox(height: 20),
          Text(
            s['attempted'] == 0
                ? 'Objective accuracy: no answers scored'
                : 'Objective accuracy: ${s['correct']}/${s['attempted']} — ${(100 * (s['correct'] as int) / (s['attempted'] as int)).round()}%',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Exact answer keys only. Skipped and unsubmitted answers earn no credit and are excluded from accuracy.',
          ),
          const SizedBox(height: 18),
          Text(
            s['possible'] == 0
                ? 'Concept coverage: no self-assessments'
                : 'Self-reported concept coverage: ${s['covered']}/${s['possible']} — ${(100 * (s['covered'] as int) / (s['possible'] as int)).round()}%',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Checklist coverage is self-assessed before the reference answer is revealed. It does not measure free-text correctness, communication quality, or professional readiness.',
          ),
          const SizedBox(height: 12),
          if ((s['weak'] as List).isNotEmpty)
            Text('Revisit: ${(s['weak'] as List).join(', ')}'),
          if (_mode == InterviewMode.practice)
            const Text(
              'Practice mode is for study; visible reference answers are not scored.',
            ),
          if (_saveError != null) Text(_saveError!),
          const SizedBox(height: 12),
          const Text(
            'Session summaries stay on this device. Typed practice answers are discarded when you leave this session. Interview practice does not award course XP.',
          ),
          _button(
            'Choose another mode',
            _saving
                ? null
                : () => setState(() {
                    _mode = null;
                    _finished = false;
                  }),
          ),
          TextButton(
            onPressed: () => context.push('/course/${widget.bank.courseId}'),
            child: const Text('Review course material'),
          ),
        ]),
      );
    }
    final q = _question, root = _pool[_index];
    final r = _response(q);
    final canSubmit =
        !q.objective ||
        q.format == InterviewFormat.ordering ||
        (q.format == InterviewFormat.codeOutput
            ? r.text.trim().isNotEmpty
            : r.selected.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode!.label),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _paused = !_paused;
              if (_paused) {
                _watch.stop();
              } else {
                _watch.start();
              }
            }),
            child: Text(_paused ? 'Resume' : 'Pause'),
          ),
          TextButton(onPressed: _finish, child: const Text('Finish')),
        ],
      ),
      body: _layout([
        Text(
          '${widget.title} · ${_index + 1}/${_pool.length} · ${_time(_watch.elapsed.inSeconds)}',
        ),
        LinearProgressIndicator(value: (_index + 1) / _pool.length),
        const SizedBox(height: 12),
        if (_paused)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Session paused. Resume to continue.'),
          ),
        IgnorePointer(
          ignoring: _paused,
          child: Opacity(
            opacity: _paused ? 0.35 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_trail.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _trail.removeLast();
                      _questionStart = _watch.elapsed.inSeconds;
                    }),
                    child: const Text('Back to previous question'),
                  ),
                Text('${q.category} · ${q.difficulty} · ${q.format.label}'),
                if (_trail.isNotEmpty)
                  Text(
                    'Follow-up to: ${root.prompt}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
                if (q.code.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CodeBlock(code: q.code, languageLabel: 'Python'),
                  ),
                if (!q.objective || q.format == InterviewFormat.codeOutput) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('answer_${q.id}'),
                    initialValue: r.text,
                    minLines: q.objective ? 1 : 3,
                    maxLines: 8,
                    enabled: !_paused && !r.revealed,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: q.objective
                          ? 'Expected output'
                          : 'Your answer (optional, self-practice)',
                    ),
                    onChanged: (value) => setState(() => r.text = value),
                  ),
                ],
                if (q.format == InterviewFormat.ordering) ...[
                  const Text(
                    'Use the arrows to arrange the steps from first to last.',
                  ),
                  for (var i = 0; i < r.order.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i + 1}. ${q.choices.firstWhere((c) => c.id == r.order[i]).text}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Move step ${i + 1} up',
                          onPressed: r.revealed || i == 0
                              ? null
                              : () => setState(() {
                                  final id = r.order.removeAt(i);
                                  r.order.insert(i - 1, id);
                                }),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Move step ${i + 1} down',
                          onPressed: r.revealed || i == r.order.length - 1
                              ? null
                              : () => setState(() {
                                  final id = r.order.removeAt(i);
                                  r.order.insert(i + 1, id);
                                }),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
                ] else if (q.choices.isNotEmpty) ...[
                  Text(
                    q.format == InterviewFormat.multiSelect ||
                            q.format == InterviewFormat.architecture
                        ? 'Select all that apply.'
                        : 'Choose one answer.',
                  ),
                  for (final c in q.choices)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.text),
                      value: r.selected.contains(c.id),
                      onChanged: _paused || r.revealed
                          ? null
                          : (checked) => setState(() {
                              if (q.format != InterviewFormat.multiSelect &&
                                  q.format != InterviewFormat.architecture) {
                                r.selected.clear();
                              }
                              if (checked == true) {
                                r.selected.add(c.id);
                              } else {
                                r.selected.remove(c.id);
                              }
                            }),
                    ),
                ],
                if (!q.objective) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Before viewing the answer, which key points did your response cover?',
                  ),
                  for (var i = 0; i < q.keyPoints.length; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(q.keyPoints[i]),
                      value: r.points.contains(i),
                      onChanged: _paused || r.revealed
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                r.points.add(i);
                              } else {
                                r.points.remove(i);
                              }
                            }),
                    ),
                ],
                if (!r.revealed) ...[
                  _button(
                    q.objective ? 'Check answer' : 'Show Answer',
                    canSubmit ? () => _reveal() : null,
                  ),
                  if (q.objective)
                    TextButton(
                      onPressed: () => _reveal(skip: true),
                      child: const Text('Skip and show answer (no score)'),
                    ),
                ],
                if (r.revealed) ...[
                  const SizedBox(height: 18),
                  if (q.objective && r.submitted)
                    Text(
                      r.correct == true
                          ? 'Correct'
                          : 'Not correct — review the answer key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (!q.objective && r.submitted)
                    Text(
                      'Self-reported concept coverage: ${r.points.length}/${q.keyPoints.length} — ${(100 * r.points.length / q.keyPoints.length).round()}%',
                    ),
                  Text(
                    'Reference answer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(q.answer),
                  if (q.objective && q.correctIds.isNotEmpty)
                    Text(
                      'Answer key: ${q.correctIds.map((id) => q.choices.firstWhere((c) => c.id == id).text).join(' → ')}',
                    ),
                  const SizedBox(height: 8),
                  if (q.objective) ...[
                    const Text('Key points expected'),
                    for (final point in q.keyPoints) Text('• $point'),
                  ],
                  for (final id in q.followUpIds)
                    _button(
                      'Follow-up: ${widget.bank.question(id).prompt}',
                      () => setState(() {
                        _trail.add(id);
                        _questionStart = _watch.elapsed.inSeconds;
                      }),
                    ),
                  _button(
                    _index == _pool.length - 1
                        ? 'Finish session'
                        : 'Next question',
                    _next,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
