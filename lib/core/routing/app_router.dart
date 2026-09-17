import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/labs/experiment_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/interview/interview_screen.dart';
import '../../features/learn/learn_screens.dart';
import '../../features/learn/mind_map_screen.dart';
import '../../features/lessons/lesson_screen.dart';
import '../../features/lessons/quiz_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/projects/project_screens.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/technologies/technology_screens.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/labs', builder: (_, _) => const ExperimentScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', redirect: (_, _) => '/profile/edit'),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const ProfileDetailsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (_, state) => LearnScreen(
                  showAll: state.uri.queryParameters['view'] == 'all',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (_, _) => const PracticeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (_, _) => const ProjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/course/:id',
        builder: (_, state) =>
            CourseDetailScreen(trackId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/:moduleId',
        redirect: (_, state) =>
            state.pathParameters['moduleId']!.endsWith('_interviews')
            ? '/interview/${state.pathParameters['id']}'
            : null,
        builder: (_, state) => CourseDetailScreen(
          trackId: state.pathParameters['id']!,
          moduleId: state.pathParameters['moduleId'],
        ),
      ),
      GoRoute(
        path: '/lesson/:id',
        redirect: (_, state) {
          final match = RegExp(r'^(track_.+)_interviews_[123]$')
              .firstMatch(state.pathParameters['id']!);
          return match == null ? null : '/interview/${match.group(1)}';
        },
        builder: (_, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id/quiz',
        builder: (_, state) =>
            QuizScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (_, state) =>
            ProjectDetailScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/tech', builder: (_, _) => const TechnologiesScreen()),
      GoRoute(
        path: '/tech/:id',
        builder: (_, state) =>
            TechnologyDetailScreen(techId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/roadmap', builder: (_, _) => const RoadmapScreen()),
      GoRoute(path: '/skills', builder: (_, _) => const SkillGraphScreen()),
      GoRoute(
        path: '/course-map',
        builder: (_, _) => const CourseMindMapScreen(),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
      GoRoute(path: '/bookmarks', builder: (_, _) => const BookmarksScreen()),
      GoRoute(path: '/interview', builder: (_, _) => const InterviewScreen()),
      GoRoute(
        path: '/interview/:id',
        builder: (_, state) =>
            InterviewScreen(trackId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/career', builder: (_, _) => const CareerScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
    ],
  );
});
