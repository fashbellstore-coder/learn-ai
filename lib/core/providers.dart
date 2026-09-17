import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/code_execution_repository.dart';
import '../data/repositories/interview_prep_repository.dart';
import '../shared/models/interview_models.dart';
import '../data/repositories/curriculum_repository.dart';
import '../data/repositories/user_repository.dart';
import '../shared/models/content_models.dart';
import '../shared/models/user_models.dart';
import 'utils/learning_math.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override SharedPreferences in main()');
});

final userControllerProvider =
    StateNotifierProvider<UserController, UserSession>((ref) {
      return UserController(ref.watch(sharedPreferencesProvider));
    });

final userProfileProvider = Provider<UserProfile>((ref) {
  return ref.watch(userControllerProvider).profile;
});

/// Loaded once at app start (see main.dart) from assets/content/<folder>/
/// module_*.json for every course that has moved to the JSON pipeline, and
/// overridden here — keyed by track id. Empty until that override is set.
final trackModuleOverridesProvider =
    Provider<Map<String, List<LearningModule>>>((ref) => const {});

final practiceBankDrillsProvider = Provider<List<QuizQuestion>>(
  (ref) => const [],
);

final practiceBankInterviewsProvider = Provider<List<InterviewItem>>(
  (ref) => const [],
);

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return SeedCurriculumRepository(
    trackOverrides: ref.watch(trackModuleOverridesProvider),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SeedCatalogRepository(
    additionalDrills: ref.watch(practiceBankDrillsProvider),
    additionalInterviews: ref.watch(practiceBankInterviewsProvider),
  );
});

final codeExecutionProvider = Provider<CodeExecutionRepository>((ref) {
  return LocalCodeExecutionRepository();
});

final tracksProvider = Provider<List<RoadmapTrack>>((ref) {
  return ref.watch(curriculumRepositoryProvider).getTracks();
});

final searchIndexProvider = Provider<SearchIndex>((ref) => const SearchIndex());

final roadmapGeneratorProvider = Provider<RoadmapGenerator>(
  (ref) => const RoadmapGenerator(),
);

final interviewPrepRepositoryProvider = Provider(
  (ref) => InterviewPrepRepository(),
);
final interviewBankProvider = FutureProvider.family<InterviewBank, String>(
  (ref, id) => ref.watch(interviewPrepRepositoryProvider).load(id),
);
