import 'enums.dart';

class CodeSnippet {
  const CodeSnippet({
    required this.language,
    required this.code,
    this.title = 'Interactive playground',
    this.explanation = '',
    this.expectedOutput = '',
    this.isEditable = true,
  });

  final CodeLanguage language;
  final String code;
  final String title;
  final String explanation;
  final String expectedOutput;
  final bool isEditable;
}

class QuizOption {
  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation = '',
  });

  final String id;
  final String text;
  final bool isCorrect;
  final String explanation;
}

class ContentSection {
  const ContentSection({required this.title, required this.content});

  final String title;
  final String content;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.explanation,
    this.codeSnippet,
    this.codeLanguage = CodeLanguage.python,
    this.hint = '',
    this.xpReward = 25,
    this.difficulty = Difficulty.medium,
    this.topic = '',
  });

  final String id;
  final String question;
  final QuizQuestionType type;
  final List<QuizOption> options;
  final String? codeSnippet;
  final CodeLanguage codeLanguage;
  final String explanation;
  final String hint;
  final int xpReward;
  final Difficulty difficulty;
  final String topic;
}

class InterviewItem {
  const InterviewItem({
    required this.question,
    required this.modelAnswer,
    this.companyTags = const ['Google', 'Meta', 'OpenAI', 'Anthropic'],
    this.followUpQuestions = const [],
    this.keyTerms = const [],
    this.topic = '',
  });

  final String question;
  final String modelAnswer;
  final List<String> companyTags;
  final List<String> followUpQuestions;
  final List<String> keyTerms;
  final String topic;
}

class PredictChallenge {
  const PredictChallenge({
    required this.code,
    required this.expectedOutput,
    this.explanation = '',
  });

  final String code;
  final String expectedOutput;
  final String explanation;
}

class CodeExercise {
  const CodeExercise({
    required this.title,
    required this.prompt,
    required this.starterCode,
    this.expectedOutput = '',
    this.hint = '',
  });

  final String title;
  final String prompt;
  final String starterCode;
  final String expectedOutput;
  final String hint;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.trackId,
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.readTimeMinutes,
    required this.xpReward,
    this.conceptOverview = '',
    this.whyItMatters = '',
    this.eli5Explanation = '',
    this.engineerDeepDive = '',
    this.realWorldAnalogy = '',
    this.sections = const [],
    this.mathFormula,
    this.mathIntuition,
    this.visualizerType = VisualizerType.none,
    this.codeSnippet,
    this.playgrounds = const [],
    this.commonMistakes = const [],
    this.interviewQuestion,
    this.quizQuestions = const [],
    this.keyTakeaways = const [],
    this.version = '2026.1',
    this.lastUpdated = '2026-08-29',
    this.relatedTechIds = const [],
    this.relatedProjectIds = const [],
    this.predictChallenge,
    this.debugChallenge,
    this.codingChallenge,
    this.miniProject,
  });

  final String id;
  final String trackId;
  final String moduleId;
  final String title;
  final String subtitle;
  final int readTimeMinutes;
  final int xpReward;
  final String conceptOverview;
  final String whyItMatters;
  final String eli5Explanation;
  final String engineerDeepDive;
  final String realWorldAnalogy;
  final List<ContentSection> sections;
  final String? mathFormula;
  final String? mathIntuition;
  final VisualizerType visualizerType;
  final CodeSnippet? codeSnippet;
  final List<CodeSnippet> playgrounds;
  final List<String> commonMistakes;

  /// One or two interactive examples the learner can run.
  List<CodeSnippet> get runnableExamples {
    if (playgrounds.isNotEmpty) return playgrounds;
    if (codeSnippet != null) return [codeSnippet!];
    return const [];
  }

  Lesson withPlaygrounds(List<CodeSnippet> next) {
    return Lesson(
      id: id,
      trackId: trackId,
      moduleId: moduleId,
      title: title,
      subtitle: subtitle,
      readTimeMinutes: readTimeMinutes,
      xpReward: xpReward,
      conceptOverview: conceptOverview,
      whyItMatters: whyItMatters,
      eli5Explanation: eli5Explanation,
      engineerDeepDive: engineerDeepDive,
      realWorldAnalogy: realWorldAnalogy,
      sections: sections,
      mathFormula: mathFormula,
      mathIntuition: mathIntuition,
      visualizerType: visualizerType,
      codeSnippet: next.isEmpty ? codeSnippet : next.first,
      playgrounds: next,
      commonMistakes: commonMistakes,
      interviewQuestion: interviewQuestion,
      quizQuestions: quizQuestions,
      keyTakeaways: keyTakeaways,
      version: version,
      lastUpdated: lastUpdated,
      relatedTechIds: relatedTechIds,
      relatedProjectIds: relatedProjectIds,
      predictChallenge: predictChallenge,
      debugChallenge: debugChallenge,
      codingChallenge: codingChallenge,
      miniProject: miniProject,
    );
  }

  Lesson relocated({required String trackId, required String moduleId}) {
    return Lesson(
      id: id,
      trackId: trackId,
      moduleId: moduleId,
      title: title,
      subtitle: subtitle,
      readTimeMinutes: readTimeMinutes,
      xpReward: xpReward,
      conceptOverview: conceptOverview,
      whyItMatters: whyItMatters,
      eli5Explanation: eli5Explanation,
      engineerDeepDive: engineerDeepDive,
      realWorldAnalogy: realWorldAnalogy,
      sections: sections,
      mathFormula: mathFormula,
      mathIntuition: mathIntuition,
      visualizerType: visualizerType,
      codeSnippet: codeSnippet,
      playgrounds: playgrounds,
      commonMistakes: commonMistakes,
      interviewQuestion: interviewQuestion,
      quizQuestions: quizQuestions,
      keyTakeaways: keyTakeaways,
      version: version,
      lastUpdated: lastUpdated,
      relatedTechIds: relatedTechIds,
      relatedProjectIds: relatedProjectIds,
      predictChallenge: predictChallenge,
      debugChallenge: debugChallenge,
      codingChallenge: codingChallenge,
      miniProject: miniProject,
    );
  }

  Lesson withPractice({
    PredictChallenge? predictChallenge,
    CodeExercise? debugChallenge,
    CodeExercise? codingChallenge,
    CodeExercise? miniProject,
    List<QuizQuestion>? quizQuestions,
  }) {
    return Lesson(
      id: id,
      trackId: trackId,
      moduleId: moduleId,
      title: title,
      subtitle: subtitle,
      readTimeMinutes: readTimeMinutes,
      xpReward: xpReward,
      conceptOverview: conceptOverview,
      whyItMatters: whyItMatters,
      eli5Explanation: eli5Explanation,
      engineerDeepDive: engineerDeepDive,
      realWorldAnalogy: realWorldAnalogy,
      sections: sections,
      mathFormula: mathFormula,
      mathIntuition: mathIntuition,
      visualizerType: visualizerType,
      codeSnippet: codeSnippet,
      playgrounds: playgrounds,
      commonMistakes: commonMistakes,
      interviewQuestion: interviewQuestion,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      keyTakeaways: keyTakeaways,
      version: version,
      lastUpdated: lastUpdated,
      relatedTechIds: relatedTechIds,
      relatedProjectIds: relatedProjectIds,
      predictChallenge: predictChallenge ?? this.predictChallenge,
      debugChallenge: debugChallenge ?? this.debugChallenge,
      codingChallenge: codingChallenge ?? this.codingChallenge,
      miniProject: miniProject ?? this.miniProject,
    );
  }

  final InterviewItem? interviewQuestion;
  final List<QuizQuestion> quizQuestions;
  final List<String> keyTakeaways;
  final String version;
  final String lastUpdated;
  final List<String> relatedTechIds;
  final List<String> relatedProjectIds;
  final PredictChallenge? predictChallenge;
  final CodeExercise? debugChallenge;
  final CodeExercise? codingChallenge;
  final CodeExercise? miniProject;
}

class LearningModule {
  const LearningModule({
    required this.id,
    required this.trackId,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String trackId;
  final String title;
  final String description;
  final List<Lesson> lessons;
}

class RoadmapTrack {
  const RoadmapTrack({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.colorHex,
    required this.description,
    required this.keySkills,
    required this.modules,
    this.prerequisiteTrackIds = const [],
    this.careerGoals = const [],
  });

  final String id;
  final int levelNumber;
  final String title;
  final String tagline;
  final String icon;
  final String colorHex;
  final String description;
  final List<String> keySkills;
  final List<LearningModule> modules;
  final List<String> prerequisiteTrackIds;
  final List<CareerGoal> careerGoals;

  List<Lesson> get lessons => modules.expand((m) => m.lessons).toList();

  RoadmapTrack appendLessons(List<Lesson> extra) {
    if (extra.isEmpty) return this;
    if (modules.isEmpty) {
      return RoadmapTrack(
        id: id,
        levelNumber: levelNumber,
        title: title,
        tagline: tagline,
        icon: icon,
        colorHex: colorHex,
        description: description,
        keySkills: keySkills,
        prerequisiteTrackIds: prerequisiteTrackIds,
        careerGoals: careerGoals,
        modules: [
          LearningModule(
            id: '${id}_extra',
            trackId: id,
            title: 'Continued',
            description: 'Additional lessons',
            lessons: extra,
          ),
        ],
      );
    }
    final head = modules.first;
    return RoadmapTrack(
      id: id,
      levelNumber: levelNumber,
      title: title,
      tagline: tagline,
      icon: icon,
      colorHex: colorHex,
      description: description,
      keySkills: keySkills,
      prerequisiteTrackIds: prerequisiteTrackIds,
      careerGoals: careerGoals,
      modules: [
        LearningModule(
          id: head.id,
          trackId: head.trackId,
          title: head.title,
          description: head.description,
          lessons: [...head.lessons, ...extra],
        ),
        ...modules.skip(1),
      ],
    );
  }

  RoadmapTrack appendModules(List<LearningModule> extra) {
    if (extra.isEmpty) return this;
    return RoadmapTrack(
      id: id,
      levelNumber: levelNumber,
      title: title,
      tagline: tagline,
      icon: icon,
      colorHex: colorHex,
      description: description,
      keySkills: keySkills,
      prerequisiteTrackIds: prerequisiteTrackIds,
      careerGoals: careerGoals,
      modules: [...modules, ...extra],
    );
  }

  RoadmapTrack withModules(List<LearningModule> next) {
    return RoadmapTrack(
      id: id,
      levelNumber: levelNumber,
      title: title,
      tagline: tagline,
      icon: icon,
      colorHex: colorHex,
      description: description,
      keySkills: keySkills,
      prerequisiteTrackIds: prerequisiteTrackIds,
      careerGoals: careerGoals,
      modules: next,
    );
  }

  LearningModule? moduleById(String moduleId) {
    for (final module in modules) {
      if (module.id == moduleId) return module;
    }
    return null;
  }
}

class ProjectStep {
  const ProjectStep({
    required this.stepNumber,
    required this.title,
    required this.explanation,
    this.codeSnippet,
    this.validationTip = '',
  });

  final int stepNumber;
  final String title;
  final String explanation;
  final CodeSnippet? codeSnippet;
  final String validationTip;
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tier,
    required this.category,
    required this.estimatedHours,
    required this.xpReward,
    required this.icon,
    required this.objective,
    required this.architectureOverview,
    required this.architectureDiagram,
    required this.techStack,
    required this.requirements,
    required this.conceptsUsed,
    required this.steps,
    required this.fullSourceCode,
    required this.testingStrategy,
    required this.deploymentGuide,
    required this.challengesAndImprovements,
  });

  final String id;
  final String title;
  final String subtitle;
  final ProjectTier tier;
  final String category;
  final String estimatedHours;
  final int xpReward;
  final String icon;
  final String objective;
  final String architectureOverview;
  final String architectureDiagram;
  final List<String> techStack;
  final List<String> requirements;
  final List<String> conceptsUsed;
  final List<ProjectStep> steps;
  final String fullSourceCode;
  final String testingStrategy;
  final String deploymentGuide;
  final List<String> challengesAndImprovements;
}

class TechnologyItem {
  const TechnologyItem({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.icon,
    required this.badgeColorHex,
    required this.whatItIs,
    required this.whyItExists,
    required this.whenToUse,
    required this.whenNotToUse,
    required this.installationCommand,
    required this.minimalExampleCode,
    required this.advancedExampleCode,
    required this.architectureOverview,
    required this.pros,
    required this.cons,
    required this.alternatives,
    required this.officialDocsUrl,
    required this.relatedProjects,
    this.versionLabel = 'current',
    this.lastUpdated = '2026-08-29',
  });

  final String id;
  final String name;
  final String tagline;
  final TechCategory category;
  final String icon;
  final String badgeColorHex;
  final String whatItIs;
  final String whyItExists;
  final List<String> whenToUse;
  final List<String> whenNotToUse;
  final String installationCommand;
  final String minimalExampleCode;
  final String advancedExampleCode;
  final String architectureOverview;
  final List<String> pros;
  final List<String> cons;
  final List<String> alternatives;
  final String officialDocsUrl;
  final List<String> relatedProjects;
  final String versionLabel;
  final String lastUpdated;
}

class SearchHit {
  const SearchHit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String route;
}

class DailyPlanItem {
  const DailyPlanItem({
    required this.title,
    required this.minutes,
    required this.kind,
    this.lessonId,
  });

  final String title;
  final int minutes;
  final String kind;
  final String? lessonId;
}

class SkillNode {
  const SkillNode({
    required this.id,
    required this.label,
    required this.dependsOn,
    this.trackId,
  });

  final String id;
  final String label;
  final List<String> dependsOn;
  final String? trackId;
}
