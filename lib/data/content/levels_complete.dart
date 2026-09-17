import '../../shared/models/content_models.dart';
import 'agents_complete.dart';
import 'appdev_complete.dart';
import 'cloud_complete.dart';
import 'cv_complete.dart';
import 'dl_complete.dart';
import 'ds_complete.dart';
import 'embeddings_complete.dart';
import 'enterprise_complete.dart';
import 'evalsec_complete.dart';
import 'finetune_complete.dart';
import 'frameworks_gap.dart';
import 'genai_complete.dart';
import 'genai_frameworks.dart';
import 'hf_complete.dart';
import 'inference_complete.dart';
import 'langgraph_complete.dart';
import 'llm_complete.dart';
import 'math_complete.dart';
import 'mcp_complete.dart';
import 'ml_complete.dart';
import 'llmops_complete.dart';
import 'mlops_complete.dart';
import 'modern_gap.dart';
import 'nlp_complete.dart';
import 'rag_complete.dart';
import 'sql_complete.dart';
import 'swe_complete.dart';
import 'transformers_complete.dart';
import 'vectordb_complete.dart';

/// Dedicated-course expansions for L1–L26 (beyond Python libraries).
Map<String, List<Lesson>> levelCompleteCourses() {
  final out = <String, List<Lesson>>{};
  void add(Map<String, List<Lesson>> part) {
    for (final e in part.entries) {
      out[e.key] = [...?out[e.key], ...e.value];
    }
  }

  add(mathCompleteCourses());
  add(dsCompleteCourses());
  add(mlCompleteCourses());
  add(dlCompleteCourses());
  add(cvCompleteCourses());
  add(nlpCompleteCourses());
  add(transformersCompleteCourses());
  add(hfCompleteCourses());
  add(genaiCompleteCourses());
  add(genaiFrameworkCourses());
  add(llmCompleteCourses());
  add(embeddingsCompleteCourses());
  add(ragCompleteCourses());
  add(finetuneCompleteCourses());
  add(agentsCompleteCourses());
  add(langgraphCompleteCourses());
  add(mcpCompleteCourses());
  add(mlopsCompleteCourses());
  add(llmopsCompleteCourses());
  add(evalsecCompleteCourses());
  add(vectordbCompleteCourses());
  add(inferenceCompleteCourses());
  add(frameworksGapCourses());
  add(modernGapCourses());
  add(sweCompleteCourses());
  add(sqlCompleteCourses());
  add(appdevCompleteCourses());
  add(cloudCompleteCourses());
  add(enterpriseCompleteCourses());
  return out;
}
