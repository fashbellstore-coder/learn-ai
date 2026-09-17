import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/core/providers.dart';
import 'package:learn_ai/core/routing/app_router.dart';
import 'package:learn_ai/core/theme/app_theme.dart';
import 'package:learn_ai/data/content/asset_curriculum_loader.dart';
import 'package:learn_ai/data/repositories/interview_prep_repository.dart';
import 'package:learn_ai/data/content/practice_bank_loader.dart';
import 'package:learn_ai/shared/models/content_models.dart';
import 'package:learn_ai/shared/models/interview_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final overrides = <String, List<LearningModule>>{};
  final drills = <QuizQuestion>[];
  final interviews = <InterviewItem>[];
  final prepRepository = InterviewPrepRepository();
  final prepBanks = <String, InterviewBank>{};
  setUpAll(() async {
    overrides.addAll(await const AssetCurriculumLoader().load());
    for (final id in overrides.keys) {
      prepBanks[id] = await prepRepository.load(id);
    }
    final bank = await const PracticeBankLoader().load();
    drills.addAll(bank.drills);
    interviews.addAll(bank.interviews);
    for (final font in {
      'PlusJakartaSans': 'assets/fonts/PlusJakartaSans.ttf',
      'IBMPlexMono': 'assets/fonts/IBMPlexMono-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final width in [390.0, 1200.0]) {
    for (final dark in [true, false]) {
      testWidgets('All app routes render at $width, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            for (final entry in prepBanks.entries)
              interviewBankProvider(entry.key)
                  .overrideWith((ref) async => entry.value),
            trackModuleOverridesProvider.overrideWithValue(overrides),
            practiceBankDrillsProvider.overrideWithValue(drills),
            practiceBankInterviewsProvider.overrideWithValue(interviews),
          ],
        );
        addTearDown(container.dispose);
        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        final catalog = container.read(catalogRepositoryProvider);
        final tracks = container.read(tracksProvider);
        final routes = [
          '/home',
          '/learn',
          '/labs',
          '/course/track_pytorch',
          '/course/track_prompt_engineering',
          '/course/track_sql/track_sql_interviews',
          '/lesson/track_sql_interviews_1',
          '/lesson/pytorch_lesson_1',
          '/project/portfolio_platform',
          '/practice',
          '/projects',
          '/profile',
          '/course/track_python',
          '/course/${tracks[1].id}',
          '/course/${tracks[1].id}/${tracks[1].modules.first.id}',
          '/lesson/py_lesson_0_1',
          '/lesson/py_lesson_0_1/quiz',
          '/project/${catalog.projects.first.id}',
          '/tech',
          '/tech/${catalog.technologies.first.id}',
          '/roadmap',
          '/skills',
          '/search',
          '/explore',
          '/bookmarks',
          '/notes',
          '/interview',
          '/interview/track_rag',
          '/career',
          '/settings',
          '/auth',
          '/onboarding',
        ];
        final theme = dark ? AppTheme.dark() : AppTheme.light();
        final capture = Platform.environment['CAPTURE_DESIGN'] == '1';
        final boundaryKey = GlobalKey();
        router.go('/home');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: theme,
                routerConfig: router,
              ),
            ),
          ),
        );
        for (final route in routes) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          if (capture &&
              width == 390 &&
              [
                '/home',
                '/learn',
                '/interview/track_rag',
                '/labs',
                '/course/track_pytorch',
                '/practice',
                '/projects',
                '/profile',
                '/lesson/py_lesson_0_1',
                '/auth',
                '/onboarding',
              ].contains(route)) {
            for (final (suffix, offset) in [
              ('', 0.0),
              if (route == '/home') ('_library', 540.0),
              if (route == '/home') ('_tools', 1060.0),
            ]) {
              if (offset > 0) {
                tester
                    .state<ScrollableState>(find.byType(Scrollable).first)
                    .position
                    .jumpTo(offset);
                await tester.pumpAndSettle();
              }
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final dir = Directory('build/design-previews')
                  ..createSync(recursive: true);
                await File(
                  '${dir.path}/${route.replaceAll('/', '_')}${suffix}_${dark ? 'dark' : 'light'}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }

          final scrolls = find.byType(Scrollable);
          if (scrolls.evaluate().isNotEmpty && route != '/onboarding') {
            final scroll = tester
                .state<ScrollableState>(scrolls.first)
                .position;
            if (scroll.hasContentDimensions &&
                scroll.maxScrollExtent.isFinite) {
              scroll.jumpTo(scroll.maxScrollExtent);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: '$route bottom');
            }
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
