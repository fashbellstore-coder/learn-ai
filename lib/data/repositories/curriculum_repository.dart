import '../../shared/models/content_models.dart';
import '../content/curriculum_seed.dart';
import '../content/curriculum_updates.dart';
import '../content/interview_seed.dart';
import '../content/practice_seed.dart';
import '../content/projects_seed.dart';
import '../content/technologies_seed.dart';

abstract class CurriculumRepository {
  List<RoadmapTrack> getTracks();
  RoadmapTrack? getTrack(String id);
  LearningModule? getModule(String trackId, String moduleId);
  Lesson? getLesson(String id);
  RoadmapTrack? trackForLesson(String lessonId);
  List<Lesson> get allLessons;
  List<SkillNode> get skillGraph;
}

abstract class CatalogRepository {
  List<Project> get projects;
  Project? project(String id);
  List<TechnologyItem> get technologies;
  TechnologyItem? technology(String id);
  List<InterviewItem> get interviews;
  List<QuizQuestion> get extraDrills;
}

class SeedCurriculumRepository implements CurriculumRepository {
  SeedCurriculumRepository({
    this._seed = const CurriculumSeed(),
    this._trackOverrides = const {},
  });

  final CurriculumSeed _seed;

  /// Loaded asynchronously from `assets/content/<folder>/` at app start
  /// (see main.dart), keyed by track id. Any track present here has its
  /// seeded modules replaced while keeping the track's own metadata
  /// (title, icon, color, tagline, ...).
  final Map<String, List<LearningModule>> _trackOverrides;

  late final List<RoadmapTrack> _tracks = _buildTracks();

  List<RoadmapTrack> _buildTracks() {
    final tracks = _seed.tracks(finalize: false);
    return finalizeCurriculum([
      for (final track in tracks)
        _trackOverrides[track.id] != null &&
                _trackOverrides[track.id]!.isNotEmpty
            ? track.withModules(_trackOverrides[track.id]!)
            : track,
    ]);
  }

  @override
  List<RoadmapTrack> getTracks() => _tracks;

  @override
  RoadmapTrack? getTrack(String id) {
    for (final track in _tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  @override
  LearningModule? getModule(String trackId, String moduleId) {
    return getTrack(trackId)?.moduleById(moduleId);
  }

  @override
  List<Lesson> get allLessons => _tracks.expand((t) => t.lessons).toList();

  @override
  Lesson? getLesson(String id) {
    for (final lesson in allLessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  @override
  RoadmapTrack? trackForLesson(String lessonId) {
    for (final track in _tracks) {
      if (track.lessons.any((l) => l.id == lessonId)) return track;
    }
    return null;
  }

  @override
  List<SkillNode> get skillGraph => _seed.skillGraph();
}

class SeedCatalogRepository implements CatalogRepository {
  SeedCatalogRepository({
    ProjectsSeed projects = const ProjectsSeed(),
    TechnologiesSeed technologies = const TechnologiesSeed(),
    InterviewSeed interviews = const InterviewSeed(),
    PracticeSeed drills = const PracticeSeed(),
    List<QuizQuestion> additionalDrills = const [],
    List<InterviewItem> additionalInterviews = const [],
  }) : _projects = projects.all(),
       _technologies = technologies.all(),
       _interviews = [...interviews.bank(), ...additionalInterviews],
       _drills = [...drills.drills(), ...additionalDrills];

  final List<Project> _projects;
  final List<TechnologyItem> _technologies;
  final List<InterviewItem> _interviews;
  final List<QuizQuestion> _drills;

  @override
  List<Project> get projects => _projects;

  @override
  Project? project(String id) {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  List<TechnologyItem> get technologies => _technologies;

  @override
  TechnologyItem? technology(String id) {
    for (final t in _technologies) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  List<InterviewItem> get interviews => _interviews;

  @override
  List<QuizQuestion> get extraDrills => _drills;
}
