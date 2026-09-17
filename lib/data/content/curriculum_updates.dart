import '../../shared/models/content_models.dart';

List<RoadmapTrack> finalizeCurriculum(List<RoadmapTrack> input) {
  final result = <RoadmapTrack>[];
  for (final course in input) {
    var next = course;
    // Move SQL from 23 to 2, shifting only the intervening levels.
    final level = course.id == 'track_sql'
        ? 2
        : course.levelNumber >= 2 && course.levelNumber < 23
        ? course.levelNumber + 1
        : course.levelNumber;
    next = RoadmapTrack(
      id: next.id,
      levelNumber: level,
      title: next.title,
      tagline: next.tagline,
      icon: next.icon,
      colorHex: next.colorHex,
      description: next.description,
      keySkills: next.keySkills,
      modules: next.modules,
      prerequisiteTrackIds: next.id == 'track_sql'
          ? const ['track_math']
          : next.prerequisiteTrackIds,
      careerGoals: next.careerGoals,
    );
    result.add(next);
  }
  result.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
  return result;
}
