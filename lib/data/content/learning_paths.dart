/// Career tracks share courses; ordering is guidance, never a global gate.
class LearningPath {
  const LearningPath(this.id, this.title, this.description, this.courseIds);
  final String id;
  final String title;
  final String description;
  final List<String> courseIds;
}

const learningPaths = [
  LearningPath(
    'foundation',
    'Foundation',
    'Start here, or revisit the prerequisites you need.',
    [
      'track_python',
      'track_math',
      'track_sql',
      'track_ds',
      'track_swe',
      'track_ai_coding',
    ],
  ),
  LearningPath(
    'ml',
    'ML Engineer',
    'Build, debug, and deploy models. Vision and language are independent specializations.',
    [
      'track_ml',
      'track_dl',
      'track_pytorch',
      'track_cv',
      'track_nlp',
      'track_mlops',
    ],
  ),
  LearningPath(
    'llm',
    'Generative AI / LLM Engineer',
    'Understand language models, then build retrieval and agent applications.',
    [
      'track_transformers',
      'track_llm_architecture',
      'track_hf',
      'track_genai',
      'track_prompt_engineering',
      'track_llm',
      'track_embeddings',
      'track_vectordb',
      'track_rag',
      'track_graphrag',
      'track_finetune',
      'track_agents',
      'track_advanced_agents',
      'track_langgraph',
      'track_mcp',
      'track_multimodal',
      'track_ai_security',
    ],
  ),
  LearningPath(
    'platform',
    'AI Platform Engineer',
    'Serve and operate AI with explicit reliability, capacity, and cost budgets.',
    [
      'track_inference',
      'track_distributed',
      'track_cloud',
      'track_mlops',
      'track_llmops',
      'track_appdev',
      'track_eval_security',
      'track_ai_security',
      'track_system_design',
      'track_enterprise',
    ],
  ),
  LearningPath(
    'research',
    'AI Research',
    'Derive, implement, and evaluate ideas with reproducible experiments.',
    [
      'track_advanced_math',
      'track_dl',
      'track_pytorch',
      'track_transformers',
      'track_llm_architecture',
      'track_distributed',
      'track_finetune',
      'track_reasoning',
      'track_eval_security',
      'track_research',
    ],
  ),
];
