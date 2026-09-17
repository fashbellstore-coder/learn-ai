import '../../shared/models/content_models.dart';
import 'curriculum_advanced.dart';
import 'specialist_courses.dart';
import 'course_scope.dart';
import 'curriculum_updates.dart';
import 'prompt_engineering.dart';
import 'curriculum_extra.dart';
import 'curriculum_foundations.dart';
import 'dedicated_courses.dart';
import 'syllabus_advanced.dart';
import 'syllabus_foundations.dart';

class CurriculumSeed {
  const CurriculumSeed();

  List<RoadmapTrack> tracks({bool finalize = true}) {
    const extra = CurriculumExtra();
    final extras = extra.lessonsByTrack();
    final syllabus = <String, List<LearningModule>>{
      ...foundationSyllabus(),
      ...advancedSyllabus(),
    };
    final merged = [...foundationTracks(), ...advancedTracks()]
        .map((track) => track.appendLessons(extras[track.id] ?? const []))
        .toList();
    final tracks =
        [
              ...merged,
              ...extra.extraTracks(),
              ...specialistCourses(),
              promptEngineeringCourse(),
            ]
            .map((track) => track.appendModules(syllabus[track.id] ?? const []))
            .map(applyDedicatedCourses)
            .map(clarifyCourseScope)
            .toList();
    tracks.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
    return finalize ? finalizeCurriculum(tracks) : tracks;
  }

  List<SkillNode> skillGraph() => [
    for (final course in tracks())
      SkillNode(
        id: course.id,
        label: course.title,
        dependsOn: course.prerequisiteTrackIds,
        trackId: course.id,
      ),
  ];
}
