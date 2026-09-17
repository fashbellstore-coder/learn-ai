import '../../shared/models/content_models.dart';

// Content lives in assets/content/prompt_engineering/module_*.json.
RoadmapTrack promptEngineeringCourse() => RoadmapTrack(
  id: "track_prompt_engineering",
  levelNumber: 56,
  title: "Prompt Engineering",
  tagline: "Design, test and improve instructions as an engineering interface.",
  icon: "terminal",
  colorHex: "#00ACC1",
  description: "Build practical prompting skills across eight modules covering task specifications, examples, context, structured outputs, grounded workflows, evaluation and reliability. General prompting material lives here; retrieval, security and deployment courses cover their specialized applications.",
  keySkills: [
    "Instruction design",
    "Few-shot examples",
    "Context design",
    "Prompt evaluation",
  ],
  prerequisiteTrackIds: ["track_genai"],
  modules: const [],
);
