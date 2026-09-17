enum CodeLanguage {
  python('Python', 'py'),
  javascript('JavaScript', 'js'),
  typescript('TypeScript', 'ts'),
  sql('SQL', 'sql'),
  bash('Bash', 'sh'),
  json('JSON', 'json'),
  yaml('YAML', 'yml');

  const CodeLanguage(this.displayName, this.extension);
  final String displayName;
  final String extension;
}

enum VisualizerType {
  none,
  neuralNetwork,
  gradientDescent,
  attentionHeatmap,
  ragPipeline,
  agentReactLoop,
  mcpArchitecture,
  vectorSearch,
  numpyArray,
  pandasFrame,
  matplotlibPlot,
  scipyLab,
}

enum QuizQuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  codeOutput,
  debug,
  conceptual,
  math,
}

enum Difficulty { easy, medium, hard, expert }

enum SkillLevel { beginner, intermediate, advanced, expert }

enum ProjectTier { beginner, intermediate, advanced, expert }

enum LearningMode { learn, practice, build, review, interview, explore }

enum LessonStatus { locked, available, inProgress, completed }

enum CareerGoal {
  aiEngineer(
    'AI Engineer',
    'Design, build, and ship end-to-end AI systems',
    'architecture',
  ),
  mlEngineer(
    'ML Engineer',
    'Train, evaluate, and deploy production models',
    'model',
  ),
  llmEngineer(
    'LLM Engineer',
    'Prompting, RAG, fine-tuning, and inference',
    'terminal',
  ),
  agentEngineer(
    'AI Agent Engineer',
    'Multi-agent workflows, tools, and MCP',
    'hub',
  ),
  cvEngineer(
    'Computer Vision Engineer',
    'Perception systems for images and video',
    'vision',
  ),
  nlpEngineer(
    'NLP Engineer',
    'Language models, retrieval, and evaluation',
    'language',
  ),
  mlopsEngineer(
    'MLOps Engineer',
    'Lifecycle, observability, and reliable delivery',
    'cloud',
  ),
  researcher(
    'Research Engineer',
    'Architectures, papers, and experimental rigor',
    'science',
  );

  const CareerGoal(this.title, this.subtitle, this.iconKey);
  final String title;
  final String subtitle;
  final String iconKey;
}

enum TechCategory {
  frameworks('Deep Learning Frameworks'),
  dataScientific('Scientific & Data Processing'),
  llmOrchestration('Agent & LLM Frameworks'),
  vectorDatabases('Vector DBs & Search'),
  inferenceEngines('High-Throughput Inference'),
  mlops('MLOps & LLMOps'),
  protocols('AI Protocols & Standards'),
  application('Application & Backend');

  const TechCategory(this.title);
  final String title;
}
