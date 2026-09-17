import '../../shared/models/content_models.dart';

/// Clarify overlapping courses without changing IDs or learner progress.
RoadmapTrack clarifyCourseScope(RoadmapTrack course) {
  final scope = switch (course.id) {
    'track_embeddings' => (
      'Embeddings & Search',
      'Representation and retrieval theory: similarity, ranking and retrieval quality.',
    ),
    'track_vectordb' => (
      'Vector Databases',
      'Database engineering: indexing decisions, filtering, tenancy, capacity and operations.',
    ),
    'track_hf' => (
      'Hugging Face',
      'Use the ecosystem: datasets, tokenizers, model loading and practical PEFT workflows.',
    ),
    'track_finetune' => (
      'LLM Fine-Tuning',
      'Understand adaptation: why PEFT works, training decisions, evaluation and production tradeoffs.',
    ),
    'track_eval_security' => (
      'AI Evaluation & Safety',
      'Measure quality, robustness and safety. Continue to AI Security for tool, retrieval and supply-chain defenses.',
    ),
    _ => null,
  };
  if (scope == null) return course;
  return RoadmapTrack(
    id: course.id,
    levelNumber: course.levelNumber,
    title: scope.$1,
    tagline: scope.$2,
    icon: course.icon,
    colorHex: course.colorHex,
    description: '${scope.$2}\n${course.description}',
    keySkills: course.keySkills,
    modules: course.modules,
    prerequisiteTrackIds: course.prerequisiteTrackIds,
    careerGoals: course.careerGoals,
  );
}
