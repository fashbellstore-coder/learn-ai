import '../../shared/models/content_models.dart';
import 'dedicated_extras.dart';
import 'full_expansions.dart';
import 'levels_complete.dart';
import 'matplotlib_complete.dart';
import 'numpy_complete.dart';
import 'pandas_complete.dart';
import 'python_complete.dart';
import 'python_labs.dart';
import 'scipy_complete.dart';

class DedicatedCourseSpec {
  const DedicatedCourseSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.existingLessonIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> existingLessonIds;
}

Map<String, List<DedicatedCourseSpec>> dedicatedCourseCatalog() => {
      'track_python': [
        const DedicatedCourseSpec(
          id: 'course_py_core',
          title: 'Python Language Core',
          description: 'Types, control flow, functions, OOP, packages, and I/O — the language before the libraries.',
          existingLessonIds: [
            'py_syntax_01', 'py_core_01', 'py_types_01', 'py_int_01', 'py_float_01',
            'py_bool_01', 'py_none_01', 'py_str_01', 'py_str_02', 'py_list_01',
            'py_list_02', 'py_tup_01', 'py_set_01', 'py_dict_01', 'py_dict_02',
            'py_if_01', 'py_for_01', 'py_while_01', 'py_fn_01', 'py_fn_02',
            'py_lambda_01', 'py_comp_01', 'py_oop_01', 'py_oop_02', 'py_hint_01',
            'py_02', 'py_mod_01', 'py_pkg_01', 'py_venv_01', 'py_iter_01',
            'py_gen_01', 'py_dec_01', 'py_file_01', 'py_exc_01', 'py_json_01',
            'py_http_01', 'py_api_01', 'py_cli_01', 'py_03', 'py_05',
          ],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_numpy',
          title: 'NumPy',
          description: 'The complete ndarray library — create, index, broadcast, linalg, and from-scratch ML.',
          existingLessonIds: ['py_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_pandas',
          title: 'Pandas',
          description: 'The complete table library — Series, DataFrames, groupby, joins, clean, and ML-ready exports.',
          existingLessonIds: ['py_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_matplotlib',
          title: 'Matplotlib',
          description: 'The complete figure library — plot types, axes, color, layout, and ML curves.',
          existingLessonIds: ['py_sci_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_scipy',
          title: 'SciPy',
          description: 'The complete scientific library — linalg, sparse, optimize, stats, and the ML-adjacent rest.',
          existingLessonIds: ['py_sci_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_fundamentals',
          title: 'Python Fundamentals',
          description: 'Install, run, print, input, and every operator — the language before types.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_types_deep',
          title: 'Data Types in Depth',
          description: 'complex, mutability, conversion, type(), and isinstance.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_strings_deep',
          title: 'Strings in Depth',
          description: 'Indexing, slicing, escapes, formatting, search, and Unicode.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_collections_deep',
          title: 'Collections in Depth',
          description: 'List methods, unpacking, nested structures, and * / **.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_control_deep',
          title: 'Control Flow in Depth',
          description: 'Nested if, match/case, nested loops, pass, and loop-else.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_functions_deep',
          title: 'Functions in Depth',
          description: 'Arguments, returns, scope, recursion, and first-class functions.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_comprehensions',
          title: 'Comprehensions',
          description: 'List, dict, set, generator, nested, and conditional forms.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_builtins',
          title: 'Built-in Functions',
          description: 'len, range, zip, map, filter, sorted, any/all, and number helpers.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_iter_deep',
          title: 'Iterators & Generators',
          description: 'iter/next, custom iterators, yield, and yield from.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_exc_files',
          title: 'Exceptions & Files',
          description: 'try/except/else/finally, raise, assert, paths, and file modes.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_mod_pkg_env',
          title: 'Modules, Packages & Environments',
          description: 'import, __main__, pip, pyproject, venv, and .env.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_oop_deep',
          title: 'Object-Oriented Programming',
          description: 'self, inheritance, MRO, polymorphism, and composition.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_adv_oop',
          title: 'Advanced OOP & Dataclasses',
          description: 'Dunders, properties, abstracts, mixins, and dataclass fields.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_dec_ctx',
          title: 'Decorators, Closures & Context Managers',
          description: 'LEGB, closures, decorator factories, and with.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_hints_regex',
          title: 'Type Hints, Regex & Dates',
          description: 'Annotations, Optional/Protocol, patterns, and timestamps.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_functional_ds',
          title: 'Functional Python & Data Structures',
          description: 'map/reduce/partial, stacks, queues, Counter, and heaps.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_stdlib',
          title: 'Standard Library',
          description: 'math, itertools, pathlib, subprocess, JSON, pickle, and logging.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_net_cli',
          title: 'HTTP, APIs & CLI',
          description: 'HTTP parts, REST, auth, argparse, and exit codes.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_async_conc',
          title: 'Async, Concurrency & Parallelism',
          description: 'async/await, the event loop, threads, processes, and the GIL.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_quality',
          title: 'Testing, Debugging & Quality',
          description: 'unittest, pytest, logging, memory, profiling, and PEP 8.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_internals',
          title: 'Internals, Packaging & Metaprogramming',
          description: 'Bytecode, import, getattr, metaclasses, wheels, and SOLID.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_projects',
          title: 'Real-World Python Projects',
          description: 'Calculator through async pipeline — fifteen mini builds.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_git',
          title: 'Git & GitHub',
          description: 'Commits, branches, PRs, protection, and why weights do not belong in git.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_seaborn',
          title: 'Seaborn',
          description: 'Statistical plots — relplot, displot, catplot, heatmaps, and EDA that decides.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_py_plotly',
          title: 'Plotly',
          description: 'Interactive figures, Express, hover, Dash, and export you can rebuild.',
          existingLessonIds: [],
        ),
      ],
      'track_math': [
        const DedicatedCourseSpec(
          id: 'course_math_la',
          title: 'Linear Algebra',
          description: 'Vectors, matrices, multiply, rank, eigenpairs — the language of tensors.',
          existingLessonIds: ['math_la_01', 'math_la_02', 'math_la_03', 'math_la_04', 'math_02', 'math_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_math_calc',
          title: 'Calculus & Optimization',
          description: 'Gradients, chain rule, partials, and the learning-rate landscape.',
          existingLessonIds: ['math_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_math_prob',
          title: 'Probability',
          description: 'Random variables, Bayes, independence, and the likelihood behind a loss.',
          existingLessonIds: ['math_03', 'math_ps_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_math_stats',
          title: 'Statistics',
          description: 'Expectation, summaries, tests, intervals, and correlation vs regression.',
          existingLessonIds: ['math_ps_02', 'math_ps_03', 'math_ps_04', 'math_ps_05'],
        ),
      ],
      'track_ds': [
        const DedicatedCourseSpec(
          id: 'course_ds_clean',
          title: 'Collection & Cleaning',
          description: 'Sources, missingness, outliers, duplicates, and label noise.',
          existingLessonIds: ['ds_core_01', 'ds_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ds_features',
          title: 'Feature Engineering',
          description: 'Create signal, scale, encode, select — inside the fold, without leakage.',
          existingLessonIds: ['ds_02', 'ds_core_03', 'ds_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ds_viz',
          title: 'Visualization',
          description: 'EDA plots, Plotly, slices, calibration, and residual charts.',
          existingLessonIds: ['ds_03', 'ds_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ds_eval',
          title: 'Splits & Evaluation',
          description: 'Leakage, stratified and time splits, nested CV, and a locked test set.',
          existingLessonIds: ['ds_01'],
        ),
      ],
      'track_ml': [
        const DedicatedCourseSpec(
          id: 'course_ml_supervised',
          title: 'Supervised Learning',
          description: 'Linear models, trees, forests, boosting, SVM, KNN, and Naive Bayes.',
          existingLessonIds: [
            'ml_sup_01', 'ml_sup_02', 'ml_sup_03', 'ml_sup_04', 'ml_sup_05', 'ml_sup_06', 'ml_03', 'ml_04',
          ],
        ),
        const DedicatedCourseSpec(
          id: 'course_ml_unsupervised',
          title: 'Unsupervised & RL',
          description: 'Clustering, PCA, anomalies, and the agent–reward loop.',
          existingLessonIds: ['ml_un_01', 'ml_un_02', 'ml_un_03', 'ml_un_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ml_metrics',
          title: 'Metrics & Validation',
          description: 'Production metrics, cross-validation, thresholds, and calibration.',
          existingLessonIds: ['ml_02', 'ml_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ml_theory',
          title: 'Bias, Variance & Regularization',
          description: 'Why models overfit and the knobs that pull them back.',
          existingLessonIds: ['ml_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ml_sklearn',
          title: 'Scikit-learn',
          description: 'Estimators, pipelines, splitters, metrics, and when to leave for a net.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_ml_xai',
          title: 'Explainability',
          description: 'SHAP, LIME, ICE/PDP, slices, and when an explanation is the attack.',
          existingLessonIds: [],
        ),
      ],
      'track_dl': [
        const DedicatedCourseSpec(
          id: 'course_dl_foundations',
          title: 'Neural Network Foundations',
          description: 'Perceptrons, activations, losses, and the three training knobs.',
          existingLessonIds: ['dl_01', 'dl_core_01', 'dl_core_02', 'dl_core_03', 'dl_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_dl_train',
          title: 'Training & Optimizers',
          description: 'Backprop, SGD/AdamW, init, normalization, and regularizing nets.',
          existingLessonIds: ['dl_03', 'dl_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_dl_arch',
          title: 'Architectures',
          description: 'CNNs, RNNs/LSTM, autoencoders, GANs, transfer learning, and residuals.',
          existingLessonIds: ['dl_02', 'dl_core_05', 'dl_core_06'],
        ),
        const DedicatedCourseSpec(
          id: 'course_dl_pytorch',
          title: 'PyTorch',
          description: 'Tensors, modules, DataLoader, AMP, checkpoints, and export paths.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_dl_tf',
          title: 'TensorFlow',
          description: 'Tensors, Keras, tf.data, SavedModel, multi-GPU, and TF Lite.',
          existingLessonIds: [],
        ),
      ],
      'track_cv': [
        const DedicatedCourseSpec(
          id: 'course_cv_pixels',
          title: 'Image Fundamentals',
          description: 'Pixels, channels, OpenCV decode, and the tensor contract.',
          existingLessonIds: ['cv_01', 'cv_core_01', 'cv_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_cv_tasks',
          title: 'Tasks & Augmentation',
          description: 'Classification vs detection vs segmentation, OCR, pose, and augments.',
          existingLessonIds: ['cv_02', 'cv_core_02', 'cv_core_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_cv_detect',
          title: 'Detection & Backbones',
          description: 'YOLO-style heads, IoU/NMS, letterbox, and the backbone timeline.',
          existingLessonIds: ['cv_03', 'cv_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_cv_opencv',
          title: 'OpenCV',
          description: 'Decode, BGR, letterbox, filters, contours, video, and dnn.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_cv_modern',
          title: 'ViT, Document AI & VLMs',
          description: 'Vision transformers, image embeddings, OCR pipelines, and multimodal products.',
          existingLessonIds: [],
        ),
      ],
      'track_nlp': [
        const DedicatedCourseSpec(
          id: 'course_nlp_text',
          title: 'Text Processing',
          description: 'Tokenization, stems, lemmas, POS, NER, and when cleaning destroys signal.',
          existingLessonIds: ['nlp_01', 'nlp_core_01', 'nlp_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_nlp_classic',
          title: 'Classical NLP',
          description: 'Bag of words, TF-IDF, n-grams, hashing, and linear baselines.',
          existingLessonIds: ['nlp_02', 'nlp_core_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_nlp_embed',
          title: 'Embeddings & Seq2Seq',
          description: 'Word2Vec, GloVe, FastText, and attention before transformers.',
          existingLessonIds: ['nlp_03', 'nlp_core_04', 'nlp_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_nlp_libs',
          title: 'NLTK & spaCy',
          description: 'Classic token/stem/stop pipelines, industrial spaCy, NER, and when to use HF.',
          existingLessonIds: [],
        ),
      ],
      'track_transformers': [
        const DedicatedCourseSpec(
          id: 'course_tr_attn',
          title: 'Attention',
          description: 'QKV, scaled dots, multi-head, and the masks that keep generation honest.',
          existingLessonIds: ['trans_01', 'tr_core_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_tr_arch',
          title: 'Architectures',
          description: 'Encoder, decoder, encoder–decoder, and the named models you will ship.',
          existingLessonIds: ['trans_02', 'tr_core_02', 'tr_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_tr_pos',
          title: 'Positions & Long Context',
          description: 'Absolute, relative, RoPE, KV cache, and why 128k is not free.',
          existingLessonIds: ['trans_03', 'tr_core_03', 'tr_core_05'],
        ),
      ],
      'track_hf': [
        const DedicatedCourseSpec(
          id: 'course_hf_hub',
          title: 'Hub & Model Cards',
          description: 'Licenses, cards, pinned revisions, and from_pretrained as infrastructure.',
          existingLessonIds: ['hf_01', 'hf_core_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_hf_data',
          title: 'Datasets & Tokenizers',
          description: 'Arrow datasets, fast tokenizers, caches, and span offsets.',
          existingLessonIds: ['hf_core_02', 'hf_core_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_hf_train',
          title: 'Trainer, PEFT & Pipelines',
          description: 'Trainer, Accelerate, LoRA adapters, and when to drop pipeline().',
          existingLessonIds: ['hf_02', 'hf_core_04', 'hf_core_05'],
        ),
      ],
      'track_genai': [
        const DedicatedCourseSpec(
          id: 'course_gen_engines',
          title: 'Generation Engines',
          description: 'What generative AI is, AR vs diffusion vs GAN, and diffusion in one page.',
          existingLessonIds: ['gen_01', 'gen_core_01', 'gen_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_prompt',
          title: 'Prompting & Sampling',
          description: 'Few-shot, CoT, temperature, top-p, structured output, and versioned prompts.',
          existingLessonIds: ['gen_02', 'gen_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_multi',
          title: 'Multimodal & Safety',
          description: 'CLIP, Whisper, VLMs, filters, and product UX for generation.',
          existingLessonIds: ['gen_core_03', 'gen_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_langchain',
          title: 'LangChain',
          description:
              'LCEL, runnables, tools, memory, callbacks, and when not to wrap everything. For orchestration and cyclic control flow, see the LangGraph course.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_langgraph',
          title: 'LangGraph',
          description:
              'Graphs, state, nodes, checkpoints, and interrupts — the control plane for agents. Builds on the LangChain course.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_autogen',
          title: 'AutoGen',
          description: 'Conversable agents, group chat, and human-in-the-loop conversations.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_crewai',
          title: 'CrewAI',
          description: 'Role-goal-backstory crews, tasks, and sequential vs hierarchical process.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_deepagents',
          title: 'Deep Agents',
          description: 'Planning, virtual files, subagents, and long-horizon loops on top of LangChain.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_llamaindex',
          title: 'LlamaIndex',
          description: 'Indexes, query engines, retrievers, and data-first RAG workflows.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_openai_agents',
          title: 'OpenAI Agents SDK',
          description: 'Agents, handoffs, guardrails, sessions, and the Runner loop.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_semantic_kernel',
          title: 'Semantic Kernel',
          description: 'Kernel, plugins, planners, and Microsoft’s orchestration model.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_phidata',
          title: 'Phidata',
          description: 'Assistants, tools, knowledge, and teams — Phidata, now Agno.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_gen_models',
          title: 'Model Families',
          description: 'GPT, Llama, Qwen, Gemma, Mistral, DeepSeek — pins, licenses, and how to pick.',
          existingLessonIds: [],
        ),
      ],
      'track_llm': [
        const DedicatedCourseSpec(
          id: 'course_llm_pretrain',
          title: 'Pretraining & Scale',
          description: 'Objectives, scaling intuition, mixtures, and contamination.',
          existingLessonIds: ['llm_core_01', 'llm_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llm_decode',
          title: 'Prompts, Tokens & Decode',
          description: 'System prompts, context cost, chat templates, and sampling vs constraints.',
          existingLessonIds: ['llm_01', 'llm_02', 'llm_core_03', 'llm_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llm_tools',
          title: 'Tools & Grounding',
          description: 'Function calling, structured output, hallucination, and citations.',
          existingLessonIds: ['llm_03', 'llm_core_05'],
        ),
      ],
      'track_embeddings': [
        const DedicatedCourseSpec(
          id: 'course_emb_basics',
          title: 'What Embeddings Are',
          description: 'A map, not understanding — training pairs, pooling, and normalize.',
          existingLessonIds: ['emb_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_emb_sim',
          title: 'Similarity & Dimensions',
          description: 'Cosine vs L2, Matryoshka, and in-domain eval queries.',
          existingLessonIds: ['emb_core_01', 'emb_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_emb_retrieve',
          title: 'Retrieval Quality',
          description: 'Hybrid search, cross-encoders, and adapting embedders to your domain.',
          existingLessonIds: ['emb_02', 'emb_core_03', 'emb_core_04'],
        ),
      ],
      'track_rag': [
        const DedicatedCourseSpec(
          id: 'course_rag_found',
          title: 'RAG Foundations',
          description: 'What RAG is, when it beats fine-tuning, and the naive pipeline’s failure.',
          existingLessonIds: ['rag_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_rag_retrieve',
          title: 'Chunking & Hybrid Search',
          description: 'Chunks you can cite, BM25 + vectors, and structure-aware splits.',
          existingLessonIds: ['rag_03', 'rag_core_01', 'rag_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_rag_advanced',
          title: 'Advanced RAG',
          description: 'HyDE, parents, graphs, rerank, citations, abstain, and agentic hops.',
          existingLessonIds: ['rag_02', 'rag_core_03', 'rag_core_04', 'rag_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_rag_graph',
          title: 'GraphRAG & Knowledge Graphs',
          description: 'Entities, triples, communities, rewrite, expansion, and compression.',
          existingLessonIds: [],
        ),
      ],
      'track_finetune': [
        const DedicatedCourseSpec(
          id: 'course_ft_when',
          title: 'When to Fine-Tune',
          description: 'Prompt vs RAG vs FT, style vs facts, and a quality gate on data.',
          existingLessonIds: ['ft_core_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ft_adapters',
          title: 'SFT & Adapters',
          description: 'Clean SFT sets, LoRA, QLoRA, and full fine-tunes.',
          existingLessonIds: ['ft_01', 'ft_core_02', 'ft_core_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ft_pref',
          title: 'Preferences & Forgetting',
          description: 'SFT vs DPO, RLHF/ORPO, and catastrophic forgetting.',
          existingLessonIds: ['ft_02', 'ft_core_04', 'ft_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ft_merge',
          title: 'Merging, Synthetic Data & Cards',
          description: 'Synthetic SFT, merge methods, quant order, guards, and adapter cards.',
          existingLessonIds: [],
        ),
      ],
      'track_agents': [
        const DedicatedCourseSpec(
          id: 'course_ag_loops',
          title: 'Agent Loops',
          description: 'Thought–action–observation, ReAct, plan-and-execute, and stop budgets.',
          existingLessonIds: ['agent_01', 'ag_core_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ag_tools',
          title: 'Tools & Memory',
          description: 'Typed tools, allow-lists, buffers, summaries, and vector memory.',
          existingLessonIds: ['agent_02', 'agent_03', 'ag_core_02', 'ag_core_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ag_multi',
          title: 'Multi-Agent & Approvals',
          description: 'Roles, routers, handoffs, and human gates on irreversible actions.',
          existingLessonIds: ['ag_core_04', 'ag_core_05'],
        ),
      ],
      'track_langgraph': [
        const DedicatedCourseSpec(
          id: 'course_lg_graphs',
          title: 'State Graphs',
          description: 'Nodes, edges, reducers, checkpoints, and time travel.',
          existingLessonIds: ['lg_01', 'lg_core_01', 'lg_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_lg_ops',
          title: 'Cycles, Humans & Observability',
          description: 'Bounded loops, interrupts, and traces you can debug.',
          existingLessonIds: ['lg_02', 'lg_core_03', 'lg_core_04'],
        ),
      ],
      'track_mcp': [
        const DedicatedCourseSpec(
          id: 'course_mcp_protocol',
          title: 'Protocol & Transports',
          description: 'Tools, resources, prompts, sampling, stdio, and HTTP/SSE.',
          existingLessonIds: ['mcp_01', 'mcp_core_01', 'mcp_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_mcp_secure',
          title: 'Auth, Clients & Servers',
          description: 'Least privilege, TypeScript clients, confused deputy, and contract tests.',
          existingLessonIds: ['mcp_02', 'mcp_03', 'mcp_core_03', 'mcp_core_04'],
        ),
      ],
      'track_mlops': [
        const DedicatedCourseSpec(
          id: 'course_ops_track',
          title: 'Tracking & Features',
          description: 'Experiment tracking, registries, feature stores, and train/serve skew.',
          existingLessonIds: ['ops_02', 'ops_core_01', 'ops_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ops_data',
          title: 'Data Versioning & Validation',
          description: 'Contracts, snapshots, label quality, PII, and splits that do not leak.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_ops_train',
          title: 'Training Jobs & Orchestration',
          description: 'Jobs not notebooks, seeds, checkpoints, configs, and retries.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_ops_serve_ml',
          title: 'Serving Classical Models',
          description: 'Batch vs online, feature parity, shadow, schemas, and model A/B.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_ops_ship',
          title: 'CI/CD, Drift & Lineage',
          description: 'Eval gates, monitoring, retrain triggers, rollback, and incident review.',
          existingLessonIds: ['ops_01', 'ops_core_03', 'ops_core_04', 'ops_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ops_observe',
          title: 'Prometheus, Grafana & OpenTelemetry',
          description: 'Scrapes, dashboards, OTel, Langfuse vs MLflow, redaction, and token SLOs.',
          existingLessonIds: [],
        ),
      ],
      'track_llmops': [
        const DedicatedCourseSpec(
          id: 'course_llo_prompt',
          title: 'Prompt Registry & Releases',
          description: 'Pins, diffs, reviews, and rollback for prompts and tool schemas.',
          existingLessonIds: ['llo_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llo_eval',
          title: 'LLM Eval Harness',
          description: 'Golden sets, judges, safety slices, and gates that can fail a promote.',
          existingLessonIds: ['llo_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llo_trace',
          title: 'Traces, Cost & Token SLOs',
          description: 'Spans, redaction, TTFT/TPOT, and dollars per successful request.',
          existingLessonIds: ['llo_02', 'llo_08'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llo_ragops',
          title: 'RAG Operations',
          description: 'Index versions, embedder pins, chunk configs, and dual-read migrations.',
          existingLessonIds: ['llo_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llo_agentops',
          title: 'Agent Operations',
          description: 'Budgets, allow-lists, dead-letters, and human gates in production.',
          existingLessonIds: ['llo_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_llo_ship',
          title: 'Ship, Canary & Fallbacks',
          description: 'Canary prompts, routers, last-good pins, and cascade caps.',
          existingLessonIds: ['llo_06', 'llo_07'],
        ),
      ],
      'track_eval_security': [
        const DedicatedCourseSpec(
          id: 'course_sec_eval',
          title: 'Evaluation',
          description: 'Offline vs online, RAG/agent metrics, and LLM-as-judge pitfalls.',
          existingLessonIds: ['sec_01', 'sec_core_01', 'sec_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_sec_secure',
          title: 'Security & Governance',
          description: 'Injection, jailbreaks, PII, supply chain, and agent tool risk.',
          existingLessonIds: ['sec_02', 'sec_03', 'sec_core_03', 'sec_core_04', 'sec_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_sec_metrics',
          title: 'Metrics & Benchmarks',
          description: 'Accuracy traps, P/R/F1, BLEU/ROUGE, perplexity, judges, and regression gates.',
          existingLessonIds: [],
        ),
      ],
      'track_vectordb': [
        const DedicatedCourseSpec(
          id: 'course_vdb_ann',
          title: 'ANN Indexes',
          description: 'Flat vs HNSW, IVF, PQ, and the recall/latency sliders.',
          existingLessonIds: ['vdb_01', 'vdb_core_01'],
        ),
        const DedicatedCourseSpec(
          id: 'course_vdb_ops',
          title: 'Filters, Rebuilds & Ops',
          description: 'Metadata ACLs, hybrid queries, consistency, tenancy, and cost.',
          existingLessonIds: ['vdb_02', 'vdb_core_02', 'vdb_core_03', 'vdb_core_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_vdb_products',
          title: 'Qdrant, Milvus, Weaviate, Pinecone, pgvector',
          description: 'A product map, hybrid search, and an exit plan so you are not stuck.',
          existingLessonIds: [],
        ),
      ],
      'track_inference': [
        const DedicatedCourseSpec(
          id: 'course_inf_runtime',
          title: 'Quantization & KV Cache',
          description: 'INT8/INT4 methods, paged attention, prefix cache, and why context is memory.',
          existingLessonIds: ['inf_01', 'inf_02', 'inf_core_01', 'inf_core_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_inf_serve',
          title: 'Serving & SLOs',
          description: 'Continuous batching, speculation, TTFT/TPOT/goodput, and queue splits.',
          existingLessonIds: ['inf_core_03', 'inf_core_04', 'inf_core_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_inf_parallel',
          title: 'Parallelism & Runtimes',
          description: 'TGI, TensorRT-LLM, tensor/pipeline parallel, multi-GPU, and memory budgets.',
          existingLessonIds: [],
        ),
        const DedicatedCourseSpec(
          id: 'course_inf_precision',
          title: 'Precision & Quantization Map',
          description: 'FP32/FP16/BF16/FP8/INT8/INT4, KV quant, and a quality gate for each pin.',
          existingLessonIds: [],
        ),
      ],
      'track_swe': [
        const DedicatedCourseSpec(
          id: 'course_swe_clean',
          title: 'Clean Code & SOLID',
          description: 'Names, small functions, SOLID, and patterns when the pain is real.',
          existingLessonIds: ['swe_01', 'swe_02'],
        ),
        const DedicatedCourseSpec(
          id: 'course_swe_dsa',
          title: 'Data Structures & Algorithms',
          description: 'Lists, hashes, graphs, heaps, Big-O, and the real n in production.',
          existingLessonIds: ['swe_03', 'swe_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_swe_design',
          title: 'System Design',
          description: 'APIs, queues, caches, SLOs, and failure modes for distributed systems.',
          existingLessonIds: ['swe_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_swe_quality',
          title: 'Testing, Git & Review',
          description: 'Unit vs integration, debugging, CI gates, docs, and technical debt.',
          existingLessonIds: ['swe_06', 'swe_07', 'swe_08'],
        ),
      ],
      'track_sql': [
        const DedicatedCourseSpec(
          id: 'course_sql_core',
          title: 'SQL Core',
          description: 'SELECT, WHERE, NULLs, JOINs, GROUP BY, and cardinality.',
          existingLessonIds: ['sql_01', 'sql_02', 'sql_03', 'sql_04'],
        ),
        const DedicatedCourseSpec(
          id: 'course_sql_adv',
          title: 'CTEs, Windows & Plans',
          description: 'Subqueries, window functions, indexes, EXPLAIN, and transactions.',
          existingLessonIds: ['sql_05', 'sql_06', 'sql_07'],
        ),
        const DedicatedCourseSpec(
          id: 'course_sql_engines',
          title: 'PostgreSQL, Redis & NoSQL',
          description: 'Postgres types, Redis as cache, NoSQL access paths, migrations, and SQL security.',
          existingLessonIds: ['sql_08'],
        ),
      ],
      'track_appdev': [
        const DedicatedCourseSpec(
          id: 'course_app_api',
          title: 'REST, FastAPI & Flask',
          description: 'Verbs, status codes, Pydantic, dependencies, async, and versioning.',
          existingLessonIds: ['app_01', 'app_02', 'app_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_app_realtime',
          title: 'Streaming, Uploads & Jobs',
          description: 'SSE, WebSockets, TTFT, files, background jobs, and backpressure.',
          existingLessonIds: ['app_05', 'app_06'],
        ),
        const DedicatedCourseSpec(
          id: 'course_app_secure',
          title: 'Auth, Limits & Microservices',
          description: 'JWT, RBAC, rate limits, cache safety, timeouts, and CORS.',
          existingLessonIds: ['app_04', 'app_07', 'app_08'],
        ),
      ],
      'track_cloud': [
        const DedicatedCourseSpec(
          id: 'course_cld_os',
          title: 'Linux, Networks & Docker',
          description: 'Processes, TLS, Dockerfiles, cgroups, and image hygiene.',
          existingLessonIds: ['cld_01', 'cld_02', 'cld_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_cld_orch',
          title: 'Kubernetes, Helm & CI/CD',
          description: 'Pods, probes, Actions, GPU plugins, and pipeline gates.',
          existingLessonIds: ['cld_04', 'cld_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_cld_cloud',
          title: 'Cloud, GPUs & Secrets',
          description: 'IAM, object/block storage, load balancers, cloud GPUs, and FinOps.',
          existingLessonIds: ['cld_06', 'cld_07', 'cld_08'],
        ),
      ],
      'track_enterprise': [
        const DedicatedCourseSpec(
          id: 'course_ent_private',
          title: 'On-Prem, Air-Gap & Private LLMs',
          description: 'Boundaries, vendoring, licenses, residency, and enterprise RAG.',
          existingLessonIds: ['ent_01', 'ent_02', 'ent_03'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ent_identity',
          title: 'SSO, RBAC & Governance',
          description: 'OIDC/SAML, SCIM, audit, responsible AI, encryption, and signed deploys.',
          existingLessonIds: ['ent_04', 'ent_05'],
        ),
        const DedicatedCourseSpec(
          id: 'course_ent_ops',
          title: 'Tenancy, HA & GPU Clusters',
          description: 'Isolation tests, quotas, DR, schedulers, serving mesh, and chargeback.',
          existingLessonIds: ['ent_06', 'ent_07', 'ent_08'],
        ),
      ],
    };

RoadmapTrack applyDedicatedCourses(RoadmapTrack track) {
  final specs = dedicatedCourseCatalog()[track.id];
  if (specs == null || specs.isEmpty) return track;
  final extras = {...dedicatedExtras(), ...pythonCompleteCourses()};
  final numpy = numpyCompleteCourses();
  final pandas = pandasCompleteCourses();
  final matplotlib = matplotlibCompleteCourses();
  final scipy = scipyCompleteCourses();
  final levels = levelCompleteCourses();
  final expansions = courseExpansions();
  final pool = {for (final lesson in track.lessons) lesson.id: lesson};
  final modules = <LearningModule>[];
  for (final spec in specs) {
    final lessons = <Lesson>[
      for (final id in spec.existingLessonIds) ?pool.remove(id),
      ...?extras[spec.id],
      ...?expansions[spec.id],
      ...?numpy[spec.id],
      ...?pandas[spec.id],
      ...?matplotlib[spec.id],
      ...?scipy[spec.id],
      ...?levels[spec.id],
    ];
    if (lessons.isEmpty) continue;
    modules.add(
      LearningModule(
        id: spec.id,
        trackId: track.id,
        title: spec.title,
        description: spec.description,
        lessons: lessons,
      ),
    );
  }
  if (pool.isNotEmpty) {
    modules.add(
      LearningModule(
        id: '${track.id}_more',
        trackId: track.id,
        title: 'More in this level',
        description: 'Additional lessons in ${track.title}.',
        lessons: pool.values.toList(),
      ),
    );
  }
  return applyPythonLabs(track.withModules(modules));
}
