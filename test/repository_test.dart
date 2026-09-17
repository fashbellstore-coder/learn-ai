import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/content/asset_curriculum_loader.dart';
import 'package:learn_ai/shared/models/content_models.dart';
import 'package:learn_ai/data/repositories/code_execution_repository.dart';
import 'package:learn_ai/data/repositories/curriculum_repository.dart';
import 'package:learn_ai/data/runtime/python_interpreter.dart';
import 'package:learn_ai/shared/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, List<LearningModule>> specialistAssets;
  setUpAll(() async {
    final assets = await const AssetCurriculumLoader().load();
    specialistAssets = Map.fromEntries(
      assets.entries.where(
        (e) => [
          'track_pytorch',
          'track_llm_architecture',
          'track_distributed',
          'track_multimodal',
          'track_advanced_agents',
          'track_system_design',
          'track_graphrag',
          'track_ai_security',
          'track_reasoning',
          'track_advanced_math',
          'track_ai_coding',
          'track_research',
          'track_prompt_engineering',
        ].contains(e.key),
      ),
    );
  });
  test('seed curriculum exposes demo lessons and skill graph', () {
    final repo = SeedCurriculumRepository(trackOverrides: specialistAssets);
    expect(repo.getTracks(), isNotEmpty);
    expect(repo.getLesson('dl_01')?.title, contains('Neural'));
    expect(repo.getLesson('rag_01')?.title, contains('RAG'));
    expect(repo.getLesson('agent_01'), isNotNull);
    expect(repo.getLesson('mcp_01'), isNotNull);
    expect(repo.getLesson('vdb_01'), isNotNull);
    expect(repo.getLesson('inf_01'), isNotNull);
    expect(repo.getLesson('py_04'), isNotNull);
    expect(repo.trackForLesson('trans_01')?.id, 'track_transformers');
    expect(repo.skillGraph, isNotEmpty);
    expect(repo.getLesson('py_core_01'), isNotNull);
    expect(repo.getLesson('py_syntax_01')?.title, 'Python Syntax');
    expect(repo.getLesson('py_types_01')?.title, 'Data Types');
    expect(repo.getLesson('py_exc_01')?.title, 'Exceptions');
    expect(repo.getLesson('py_api_01')?.title, 'APIs');
    expect(repo.getLesson('seaborn_01')?.title, 'Seaborn');
    expect(repo.getLesson('jupyter_01')?.title, 'Jupyter Notebooks');
    expect(repo.getLesson('py_str_01')?.title, 'Strings');
    expect(repo.getLesson('py_list_01')?.title, 'Lists');
    expect(repo.getLesson('py_tup_01')?.title, 'Tuples');
    expect(repo.getLesson('py_set_01')?.title, 'Sets');
    expect(repo.getLesson('py_dict_01')?.title, 'Dictionaries');
    expect(repo.getLesson('ml_svm_01')?.title, 'Support Vector Machines');
    expect(repo.getLesson('nlp_tok_01')?.title, 'Tokenization');
    expect(repo.getLesson('rag_core_01'), isNotNull);
    expect(repo.getLesson('ag_core_01'), isNotNull);
    for (final track in repo.getTracks()) {
      expect(
        track.lessons.length,
        greaterThanOrEqualTo(6),
        reason: '${track.id} should be a full course',
      );
      expect(
        track.modules.length,
        greaterThanOrEqualTo(2),
        reason: '${track.id} should split into dedicated courses',
      );
      for (final module in track.modules) {
        expect(
          module.lessons.length,
          greaterThanOrEqualTo(3),
          reason:
              '${track.id} / ${module.title} should be a full dedicated course',
        );
      }
    }
    final python = repo.getTrack('track_python')!;
    expect(
      python.modules.map((m) => m.title),
      containsAll([
        'Python Language Core',
        'NumPy',
        'Pandas',
        'Matplotlib',
        'SciPy',
        'Python Fundamentals',
        'Functions in Depth',
        'Real-World Python Projects',
      ]),
    );
    expect(repo.getModule('track_python', 'course_py_numpy')?.title, 'NumPy');
    expect(repo.getLesson('numpy_02'), isNotNull);
    expect(repo.getLesson('np_what_01')?.title, 'What is NumPy?');
    expect(repo.getLesson('np_proj_nn_01'), isNotNull);
    expect(repo.getLesson('pd_what_01')?.title, 'What is Pandas?');
    expect(repo.getLesson('pd_proj_mlready_01'), isNotNull);
    expect(repo.getLesson('mpl_what_01')?.title, 'What is Matplotlib?');
    expect(repo.getLesson('mpl_proj_train_01'), isNotNull);
    expect(repo.getLesson('mpl_proj_anim_01'), isNotNull);
    expect(repo.getLesson('sp_what_01')?.title, 'What is SciPy?');
    expect(repo.getLesson('sp_proj_opt_01'), isNotNull);
    expect(
      repo.getModule('track_python', 'course_py_scipy')!.lessons.length,
      greaterThanOrEqualTo(40),
      reason: 'SciPy should include the complete 15-section syllabus',
    );
    expect(
      repo.getModule('track_python', 'course_py_matplotlib')!.lessons.length,
      greaterThanOrEqualTo(40),
      reason: 'Matplotlib should include the complete 54-section syllabus',
    );
    expect(
      repo.getModule('track_python', 'course_py_pandas')!.lessons.length,
      greaterThanOrEqualTo(40),
      reason: 'Pandas should include the complete 42-section syllabus',
    );
    expect(
      repo.getModule('track_python', 'course_py_numpy')!.lessons.length,
      greaterThanOrEqualTo(40),
      reason: 'NumPy should include the complete 38-section syllabus',
    );
    final leftover = repo.getTracks().where(
      (t) => t.modules.any((m) => m.id.endsWith('_more')),
    );
    expect(
      leftover,
      isEmpty,
      reason: 'every lesson should land in a dedicated course',
    );
    final ids = repo.allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'lesson ids must be unique');
    expect(
      repo.allLessons.length,
      greaterThanOrEqualTo(400),
      reason: 'curriculum should be a full multi-course syllabus',
    );
    expect(
      python.lessons.length,
      greaterThanOrEqualTo(50),
      reason: 'Python language core should be a full course',
    );
    expect(repo.getLesson('mla2_span_01'), isNotNull);
    expect(repo.getLesson('dsc2_contract_01'), isNotNull);
    expect(repo.getLesson('mls2_problem_01'), isNotNull);
    expect(repo.getLesson('dlf2_perceptron_01'), isNotNull);
    expect(repo.getModule('track_dl', 'course_dl_tf')?.title, 'TensorFlow');
    expect(repo.getLesson('cvp2_pixel_01'), isNotNull);
    expect(repo.getLesson('nlpt2_uni_01'), isNotNull);
    expect(repo.getLesson('tra2_qkv_01'), isNotNull);
    expect(repo.getLesson('hfh2_rev_01'), isNotNull);
    expect(repo.getLesson('gnlc2_what_01'), isNotNull);
    expect(repo.getLesson('gnlg2_what_01'), isNotNull);
    expect(repo.getLesson('gnag2_what_01'), isNotNull);
    expect(repo.getLesson('gncr2_what_01'), isNotNull);
    expect(repo.getLesson('gnda2_what_01'), isNotNull);
    expect(repo.getLesson('gnli2_what_01'), isNotNull);
    expect(repo.getLesson('gnoa2_what_01'), isNotNull);
    expect(repo.getLesson('gnsk2_what_01'), isNotNull);
    expect(repo.getLesson('gnph2_what_01'), isNotNull);
    expect(
      repo.getModule('track_genai', 'course_gen_langchain')?.title,
      'LangChain',
    );
    expect(
      repo.getModule('track_genai', 'course_gen_phidata')?.title,
      'Phidata',
    );
    expect(
      repo.getTrack('track_genai')!.modules.length,
      greaterThanOrEqualTo(12),
      reason:
          'Generative AI should include core courses plus the nine frameworks',
    );
    expect(repo.getLesson('embb2_map_01'), isNotNull);
    expect(repo.getLesson('ragf2_what_01'), isNotNull);
    expect(repo.getLesson('ftw2_prompt'), isNotNull);
    expect(repo.getTrack('track_mlops')?.title, 'MLOps');
    expect(repo.getTrack('track_mlops')?.levelNumber, 18);
    expect(repo.getTrack('track_llmops')?.title, 'LLMOps');
    expect(repo.getTrack('track_llmops')?.levelNumber, 19);
    expect(repo.getTrack('track_eval_security')?.levelNumber, 20);
    expect(repo.getTrack('track_vectordb')?.levelNumber, 21);
    expect(repo.getTrack('track_inference')?.levelNumber, 22);
    expect(repo.getLesson('llo_01'), isNotNull);
    expect(repo.getLesson('llop2_art'), isNotNull);
    expect(repo.getLesson('opd2_contract'), isNotNull);
    expect(
      repo.getModule('track_mlops', 'course_ops_data')?.title,
      'Data Versioning & Validation',
    );
    expect(
      repo.getModule('track_llmops', 'course_llo_prompt')?.title,
      'Prompt Registry & Releases',
    );
    expect(
      repo.getTrack('track_mlops')!.modules.length,
      greaterThanOrEqualTo(5),
      reason: 'MLOps should be a full level of dedicated courses',
    );
    expect(
      repo.getTrack('track_llmops')!.modules.length,
      greaterThanOrEqualTo(6),
      reason: 'LLMOps should be a full level of dedicated courses',
    );
    expect(repo.getLesson('sece2_off'), isNotNull);
    expect(repo.getLesson('vdba2_flat'), isNotNull);
    expect(repo.getLesson('infr2_kv'), isNotNull);
    expect(repo.getTrack('track_swe')?.title, 'Software Engineering');
    expect(repo.getTrack('track_swe')?.levelNumber, 23);
    expect(repo.getTrack('track_sql')?.title, 'SQL & Databases');
    expect(repo.getTrack('track_sql')?.levelNumber, 2);
    expect(repo.getTrack('track_appdev')?.title, 'AI Application Development');
    expect(repo.getTrack('track_appdev')?.levelNumber, 24);
    expect(repo.getTrack('track_cloud')?.title, 'Cloud & Infrastructure');
    expect(repo.getTrack('track_cloud')?.levelNumber, 25);
    expect(
      repo.getTrack('track_enterprise')?.title,
      'Enterprise AI Engineering',
    );
    expect(repo.getTrack('track_enterprise')?.levelNumber, 26);
    expect(repo.getLesson('swe_01'), isNotNull);
    expect(repo.getLesson('sql_01'), isNotNull);
    expect(repo.getLesson('app_01'), isNotNull);
    expect(repo.getLesson('cld_01'), isNotNull);
    expect(repo.getLesson('ent_01'), isNotNull);
    expect(repo.getLesson('pyg2_what')?.title, 'What Git Is');
    expect(repo.getLesson('seb2_what')?.title, 'What Seaborn Is');
    expect(repo.getLesson('ply2_what')?.title, 'What Plotly Is');
    expect(repo.getLesson('skl2_what'), isNotNull);
    expect(repo.getLesson('pth2_what'), isNotNull);
    expect(repo.getLesson('tfk2_what'), isNotNull);
    expect(repo.getLesson('ocv2_what'), isNotNull);
    expect(repo.getLesson('nll2_nltk'), isNotNull);
    expect(repo.getLesson('gnmf2_map'), isNotNull);
    expect(repo.getLesson('rgg2_what'), isNotNull);
    expect(
      repo.getModule('track_python', 'course_py_git')?.title,
      'Git & GitHub',
    );
    expect(
      repo.getModule('track_python', 'course_py_seaborn')?.title,
      'Seaborn',
    );
    expect(
      repo.getModule('track_ml', 'course_ml_sklearn')?.title,
      'Scikit-learn',
    );
    expect(repo.getModule('track_sql', 'course_sql_core')?.title, 'SQL Core');
    expect(repo.getTrack('track_swe')!.modules.length, greaterThanOrEqualTo(4));
    expect(repo.getTrack('track_sql')!.modules.length, greaterThanOrEqualTo(3));
    expect(
      repo.getModule('track_dl', 'course_dl_foundations')!.lessons.length,
      greaterThanOrEqualTo(9),
    );
    expect(
      repo.getModule('track_cv', 'course_cv_pixels')!.lessons.length,
      greaterThanOrEqualTo(9),
    );
    expect(
      repo.getModule('track_transformers', 'course_tr_attn')!.lessons.length,
      greaterThanOrEqualTo(9),
    );
  });

  test('catalog repositories resolve projects and technologies', () {
    final catalog = SeedCatalogRepository();
    expect(catalog.project('proj_02')?.category, contains('RAG'));
    expect(catalog.technology('tech_mcp')?.id, 'tech_mcp');
    expect(catalog.technology('tech_faiss')?.id, 'tech_faiss');
    expect(catalog.technology('tech_tensorflow')?.name, 'TensorFlow');
    expect(catalog.technology('tech_fastapi')?.name, 'FastAPI');
    expect(catalog.technology('tech_git')?.name, 'Git');
    expect(catalog.technology('tech_github')?.name, 'GitHub');
    expect(catalog.technology('tech_docker')?.name, 'Docker');
    expect(catalog.technology('tech_kubernetes')?.name, 'Kubernetes');
    expect(catalog.project('proj_08'), isNotNull);
    expect(catalog.interviews, isNotEmpty);
    expect(catalog.extraDrills, isNotEmpty);
  });

  test('local code sandbox never throws raw exceptions', () {
    final engine = LocalCodeExecutionRepository();
    expect(engine.run(CodeLanguage.python, '').isSuccess, isFalse);
    expect(engine.run(CodeLanguage.json, '{"ok":true}').isSuccess, isTrue);
    expect(engine.run(CodeLanguage.python, 'print("hi")').stdout, 'hi');
    expect(
      engine.run(CodeLanguage.python, 'x = 3\ny = x\nx = 4\nprint(y)').stdout,
      '3',
    );
    expect(
      engine.run(CodeLanguage.python, 'print(len({1,1,2}), [1,2][0])').stdout,
      '2 1',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            'print([n*n for n in range(4) if n % 2 == 0])',
          )
          .stdout,
      '[0, 4]',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            'def add(a, b=1):\n    return a + b\nprint(add(2), add(2, 3))',
          )
          .stdout,
      '3 5',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            'import json\nprint(json.loads(\'{"k":1}\')["k"])',
          )
          .stdout,
      '1',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            's = "learn"\nprint(s[0], s[4], len(s))\nprint(s + "!")',
          )
          .stdout,
      'l n 5\nlearn!',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            'print(len({1, 1, 2}))\nprint(1 in {1, 2})\nprint(3 in {1, 2})',
          )
          .stdout,
      '2\nTrue\nFalse',
    );
    expect(
      engine
          .run(
            CodeLanguage.python,
            'd = {"lr": 0.001, "epochs": 10}\nprint(d["lr"])\nprint("batch" in d)\nprint(len(d))',
          )
          .stdout,
      '0.001\nFalse\n2',
    );
  });

  test('every Python lesson has two runnable examples and a practice loop', () {
    final repo = SeedCurriculumRepository(trackOverrides: specialistAssets);
    final python = repo.getTrack('track_python')!;
    for (final lesson in python.lessons.where(
      (l) => !l.moduleId.endsWith('_interviews'),
    )) {
      expect(
        lesson.runnableExamples.length,
        greaterThanOrEqualTo(2),
        reason: '${lesson.id} ${lesson.title} needs two playgrounds',
      );
      expect(
        lesson.predictChallenge,
        isNotNull,
        reason: '${lesson.id} needs Predict the output',
      );
      expect(
        lesson.debugChallenge,
        isNotNull,
        reason: '${lesson.id} needs a debug challenge',
      );
      expect(
        lesson.codingChallenge,
        isNotNull,
        reason: '${lesson.id} needs a coding challenge',
      );
      expect(
        lesson.miniProject,
        isNotNull,
        reason: '${lesson.id} needs a mini project',
      );
      expect(
        lesson.quizQuestions,
        isNotEmpty,
        reason: '${lesson.id} needs a quiz',
      );
    }
  });

  test('python playground snippets match the in-app interpreter', () {
    final repo = SeedCurriculumRepository(trackOverrides: specialistAssets);
    const interp = PythonInterpreter();
    final python = repo.getTrack('track_python')!;
    for (final lesson in python.lessons.where(
      (l) => !l.moduleId.endsWith('_interviews'),
    )) {
      for (final snippet in lesson.runnableExamples) {
        if (snippet.expectedOutput.isEmpty) continue;
        final result = interp.run(snippet.code);
        expect(
          result.ok,
          isTrue,
          reason:
              '${lesson.id} / ${snippet.title}: ${result.stderr}\n${snippet.code}',
        );
        expect(
          result.stdout.trim(),
          snippet.expectedOutput.trim(),
          reason: '${lesson.id} / ${snippet.title}',
        );
      }
    }
  });
}
