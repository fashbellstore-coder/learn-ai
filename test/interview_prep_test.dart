import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/routing/app_router.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/data/repositories/interview_prep_repository.dart';
import 'package:learn_ai/features/interview/interview_screen.dart';
import 'package:learn_ai/shared/models/interview_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InterviewBank rag;
  setUpAll(() async {
    rag = await InterviewPrepRepository().load('track_rag');
  });
  test('every course has validated deterministic pools, formats and follow-up trees', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/content/courses.json'),
    ) as Map<String, dynamic>;
    final repo = InterviewPrepRepository();
    final formats = <InterviewFormat>{};
    for (final entry in manifest['courses'] as List) {
      final bank = await repo.load(entry['trackId'] as String);
      expect(bank.session(InterviewMode.rapidFire).length, 20);
      expect(bank.session(InterviewMode.mock).length, 10);
      expect(
        bank
            .session(InterviewMode.scenario)
            .every((q) => q.format == InterviewFormat.scenario),
        isTrue,
      );
      expect(
        bank.session(InterviewMode.mock).map((q) => q.format).toSet().length,
        greaterThanOrEqualTo(6),
      );
      expect(bank.questions.any((q) => q.followUpIds.isNotEmpty), isTrue);
      formats.addAll(bank.questions.map((q) => q.format));
    }
    expect(formats, containsAll(InterviewFormat.values));
    expect(rag.question('rag_similarity').followUpIds, [
      'rag_chunk_experiment',
    ]);
    expect(rag.question('rag_chunk_experiment').followUpIds, [
      'rag_generation_failure',
    ]);
    expect(
      rag.session(InterviewMode.mock).map((q) => q.id),
      rag.session(InterviewMode.mock).map((q) => q.id),
    );
  });
  test('objective scoring rejects extra selections and wrong order; text is never graded', () {
    final multi = rag.questions.firstWhere(
      (q) => q.format == InterviewFormat.multiSelect,
    );
    final r = PrepResponse()..selected.addAll(multi.correctIds);
    expect(scoreInterviewAnswer(multi, r), isTrue);
    r.selected.add('invented');
    expect(scoreInterviewAnswer(multi, r), isFalse);
    final ordering = rag.questions.firstWhere(
      (q) => q.format == InterviewFormat.ordering,
    );
    r.order = ordering.correctIds.reversed.toList();
    expect(scoreInterviewAnswer(ordering, r), isFalse);
    r.order = [...ordering.correctIds];
    expect(scoreInterviewAnswer(ordering, r), isTrue);
    final output = rag.questions.firstWhere(
      (q) => q.format == InterviewFormat.codeOutput,
    );
    r.text = '60\n';
    expect(scoreInterviewAnswer(output, r), isTrue);
    r.text = '60 percent';
    expect(scoreInterviewAnswer(output, r), isFalse);
    expect(
      () => scoreInterviewAnswer(rag.question('rag_similarity'), r),
      throwsArgumentError,
    );
  });

  Future<SharedPreferences> mount(
    WidgetTester tester, {
    double width = 390,
    bool dark = true,
    InterviewBank? bankOverride,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          interviewBankProvider('track_rag')
              .overrideWith((ref) async => bankOverride ?? rag),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const InterviewScreen(trackId: 'track_rag'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'typed practice, checklist locking, fixed follow-ups and local summary',
    (tester) async {
      final prefs = await mount(tester);
      await tester.tap(find.text('Interview'));
      await tester.pump();
      expect(find.text('Reference answer'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField),
        'My own answer about chunking',
      );
      final first = find.byType(CheckboxListTile).first;
      await reveal(tester, first);
      await tester.tap(first);
      await tester.pump();
      await reveal(tester, find.text('Show Answer'));
      await tester.tap(find.text('Show Answer'));
      await tester.pump();
      expect(
        find.text('Self-reported concept coverage: 1/7 — 14%'),
        findsOneWidget,
      );
      expect(tester.widget<CheckboxListTile>(first).onChanged, isNull);
      final follow = find.text(
        'Follow-up: ${rag.question('rag_chunk_experiment').prompt}',
      );
      await reveal(tester, follow);
      await tester.tap(follow);
      await tester.pump();
      expect(
        find.text(rag.question('rag_chunk_experiment').prompt),
        findsOneWidget,
      );
      expect(find.text('Reference answer'), findsNothing);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(
        find.text('Objective accuracy: no answers scored'),
        findsOneWidget,
      );
      expect(
        find.text('Self-reported concept coverage: 1/7 — 14%'),
        findsOneWidget,
      );
      final saved = prefs.getString('learn_ai.interview_prep.v1.track_rag')!;
      expect(saved, isNot(contains('My own answer')));
      expect((jsonDecode(saved) as List).single['covered'], 1);
    },
  );
  testWidgets(
    'objective submission locks choices and persists a distinct objective score',
    (tester) async {
      final q = rag.questions.firstWhere(
        (q) => q.format == InterviewFormat.multiSelect,
      );
      final single = InterviewBank(
        courseId: 'track_rag',
        questions: [q],
        pools: {
          for (final mode in InterviewMode.values) mode.name: [q.id],
        },
      );
      final prefs = await mount(tester, bankOverride: single);
      await tester.tap(find.text('Interview'));
      await tester.pump();
      for (final id in q.correctIds) {
        final choice = find.text(q.choices.firstWhere((c) => c.id == id).text);
        await reveal(tester, choice);
        await tester.tap(choice);
        await tester.pump();
      }
      await reveal(tester, find.text('Check answer'));
      await tester.tap(find.text('Check answer'));
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('Objective accuracy: 1/1 — 100%'), findsOneWidget);
      expect(
        find.text('Concept coverage: no self-assessments'),
        findsOneWidget,
      );
      final summary = (jsonDecode(
        prefs.getString('learn_ai.interview_prep.v1.track_rag')!,
      ) as List).first;
      expect(summary['correct'], 1);
      expect(summary['possible'], 0);
    },
  );
  for (final width in [360.0, 1024.0]) {
    for (final dark in [false, true]) {
      testWidgets('practice shows reference immediately at $width dark=$dark', (
        tester,
      ) async {
        await mount(tester, width: width, dark: dark);
        await tester.tap(find.text('Practice'));
        await tester.pump();
        expect(find.text('Reference answer'), findsOneWidget);
        expect(find.text('Show Answer'), findsNothing);
        await tester.tap(find.text('Pause'));
        await tester.pump();
        expect(
          find.text('Session paused. Resume to continue.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Resume'));
        await tester.pump();
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();
        expect(
          find.text('Concept coverage: no self-assessments'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('old interview lessons redirect to course prep', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        interviewBankProvider('track_rag').overrideWith((ref) async => rag),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/lesson/track_rag_interviews_1');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mock Interview'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/interview/track_rag',
    );
  });
}
