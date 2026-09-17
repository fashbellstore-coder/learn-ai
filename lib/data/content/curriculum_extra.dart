import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import 'curriculum_gap.dart';
import 'lesson_factory.dart';

/// Extra lessons merged into existing tracks, plus two production tracks.
class CurriculumExtra {
  const CurriculumExtra();

  Map<String, List<Lesson>> lessonsByTrack() => {
        'track_python': [_pandas(), _errors()],
        'track_math': [_svd()],
        'track_ds': [_eda()],
        'track_ml': [_linreg(), _cvfold()],
        'track_dl': [_backprop(), _optim()],
        'track_cv': [_yolo()],
        'track_nlp': [_embedWords()],
        'track_transformers': [_rope()],
        'track_hf': [_peft()],
        'track_genai': [_diffusion()],
        'track_llm': [_tools()],
        'track_embeddings': [_hybrid()],
        'track_rag': [_chunk()],
        'track_finetune': [_dpo()],
        'track_agents': [_toolsafety()],
        'track_langgraph': [_hitl()],
        'track_mcp': [_tsClient()],
        'track_mlops': [_mlflow()],
        'track_eval_security': [_indirect()],
      };

  List<RoadmapTrack> extraTracks() => [_vectorDb(), _inference(), ...gapTracks()];
}

Lesson _pandas() => lesson(
      id: 'py_04',
      trackId: 'track_python',
      moduleId: 'mod_py_01',
      title: 'Pandas for Feature Tables',
      subtitle: 'The dataframe is the unit of work before a tensor exists',
      minutes: 9,
      xp: 50,
      concept:
          'Pandas stores labeled rows and columns. AI pipelines use it to join, filter, impute, and emit NumPy/Parquet before training.',
      why: 'Most production bugs are join keys and silent NaNs, not model architecture.',
      eli5: 'A spreadsheet that can filter a million rows without you clicking.',
      engineer:
          'Prefer `assign` over chained mutation. Set dtypes early. Use `merge` with `validate` to catch one-to-many explosions.',
      analogy: 'A warehouse inventory sheet that updates itself when a truck arrives.',
      code: py(
        'Clean a tiny table',
        r'''
import pandas as pd
df = pd.DataFrame({"user":[1,1,2], "spend":[10, None, 4]})
df["spend"] = df["spend"].fillna(df["spend"].median())
print(df.groupby("user")["spend"].sum().to_dict())
''',
        expected: '{1: 20.0, 2: 4.0}',
      ),
      mistakes: const ['Chained assignment', 'Joining on unclean IDs'],
      quiz: [
        mcq(
          id: 'q_py_04',
          question: 'Why set dtypes before a big join?',
          options: [
            opt('1', 'Wrong types silently drop or explode keys', true),
            opt('2', 'Pandas refuses floats otherwise', false),
            opt('3', 'It trains the model faster', false),
          ],
          explanation: 'int vs string keys look equal to humans and unequal to the join.',
          topic: 'Pandas',
        ),
      ],
      takeaways: const ['Tables before tensors.', 'Validate merges.'],
      tech: const ['tech_numpy'],
    );

Lesson _errors() => lesson(
      id: 'py_05',
      trackId: 'track_python',
      moduleId: 'mod_py_01',
      title: 'Exceptions, Files & JSON Contracts',
      subtitle: 'APIs fail. Your training job should not.',
      minutes: 8,
      xp: 45,
      concept:
          'Catch expected I/O and schema errors at the boundary. Let unexpected exceptions crash the job so you notice.',
      why: 'Silent `except Exception: pass` is how bad labels enter a registry.',
      eli5: 'If the oven is on fire, do not keep baking and smile.',
      engineer: 'Use context managers for files. Validate JSON with a schema (Pydantic) before training.',
      analogy: 'A loading dock that rejects unlabeled crates.',
      code: py(
        'Safe JSON load',
        r'''
import json
raw = '{"split":"train","n":3}'
payload = json.loads(raw)
if "split" not in payload:
    raise ValueError("missing split")
print(payload["split"], payload["n"])
''',
        expected: 'train 3',
      ),
      quiz: [
        mcq(
          id: 'q_py_05',
          question: 'What should a training entrypoint do on an unknown exception?',
          options: [
            opt('1', 'Fail the job and alert', true),
            opt('2', 'Swallow it and write a dummy metric', false),
            opt('3', 'Retry forever with no backoff', false),
          ],
          explanation: 'Unknown failures hide data bugs. Crash loudly.',
          topic: 'Python',
        ),
      ],
      takeaways: const ['Fail closed on schema.', 'Catch only expected errors.'],
    );

Lesson _svd() => lesson(
      id: 'math_04',
      trackId: 'track_math',
      moduleId: 'mod_math_01',
      title: 'SVD, PCA & Why Embeddings Are Short',
      subtitle: 'Compress a matrix into directions that carry energy',
      minutes: 10,
      xp: 60,
      concept:
          'SVD writes A = UΣVᵀ. PCA keeps the top singular vectors. Embeddings and LSA are the same geometry with different branding.',
      why: 'Dimensionality reduction, recommendation, and initialization all use this decomposition.',
      eli5: 'Keep the loudest notes of a song and drop the hiss.',
      engineer: 'Center the data before PCA. Truncated SVD scales to sparse TF-IDF.',
      analogy: 'A shadow that still looks like the object because it kept the main outline.',
      formula: 'A ≈ U_k Σ_k V_kᵀ',
      mathIntuition: 'The first k singular values capture the dominant variance.',
      code: py(
        'Tiny SVD',
        r'''
import numpy as np
A = np.array([[2., 0.],[1., 1.],[0., 2.]])
U, S, Vt = np.linalg.svd(A, full_matrices=False)
print(tuple(S.round(2)))
''',
        expected: '(2.45, 1.41)',
      ),
      quiz: [
        mcq(
          id: 'q_math_04',
          question: 'PCA on embeddings is closest to',
          options: [
            opt('1', 'Keeping top singular vectors of a centered matrix', true),
            opt('2', 'Dropout', false),
            opt('3', 'Beam search', false),
          ],
          explanation: 'PCA is truncated SVD after mean subtraction.',
          topic: 'Linear algebra',
        ),
      ],
      takeaways: const ['SVD finds energy directions.', 'Center before PCA.'],
    );

Lesson _eda() => lesson(
      id: 'ds_03',
      trackId: 'track_ds',
      moduleId: 'mod_ds_01',
      title: 'EDA That Changes the Model',
      subtitle: 'Plots are only useful if they change a decision',
      minutes: 8,
      xp: 50,
      concept:
          'Exploratory analysis hunts leakage, skew, and impossible values. A histogram of label dates often kills a “brilliant” feature.',
      why: 'You cannot regularize a feature that is the target in disguise.',
      eli5: 'Look at the cookies before you taste-test. Some might be plastic.',
      engineer: 'Always plot target vs time, missingness maps, and a few pairwise joints for suspects.',
      analogy: 'A building inspector walking the site before the architect signs off.',
      code: py(
        'Skew check',
        r'''
xs = [1, 1, 1, 2, 2, 30]
mean = sum(xs)/len(xs)
print(round(mean, 2), max(xs))
''',
        expected: '6.17 30',
      ),
      quiz: [
        mcq(
          id: 'q_ds_03',
          question: 'A feature that is a perfect predictor on train only is usually',
          options: [
            opt('1', 'Leakage or an ID', true),
            opt('2', 'Proof the loss is convex', false),
            opt('3', 'A reason to skip a test set', false),
          ],
          explanation: 'Perfect train signal that fails live is the leakage fingerprint.',
          topic: 'EDA',
        ),
      ],
      takeaways: const ['EDA is a decision tool.', 'Time plots catch leakage.'],
    );

Lesson _linreg() => lesson(
      id: 'ml_04',
      trackId: 'track_ml',
      moduleId: 'mod_ml_01',
      title: 'Linear Regression from the Normal Equation',
      subtitle: 'The baseline you must beat',
      minutes: 9,
      xp: 55,
      concept:
          'Ordinary least squares solves ŵ = (XᵀX)⁻¹Xᵀy when XᵀX is invertible. Regularization (Ridge) adds λI.',
      why: 'If a linear model is enough, a transformer is waste. Always publish the baseline.',
      eli5: 'Draw the straight line that misses the dots by the least amount.',
      engineer: 'Ill-conditioned XᵀX is why we prefer QR/SVD solvers over a naive inverse.',
      analogy: 'Fitting a ruler through a cloud of pencil marks.',
      formula: 'ŵ = (XᵀX + λI)⁻¹ Xᵀy',
      code: py(
        'OLS in NumPy',
        r'''
import numpy as np
X = np.array([[1,1],[1,2],[1,3]], float)
y = np.array([2,3,4], float)
w, *_ = np.linalg.lstsq(X, y, rcond=None)
print(w.round(2).tolist())
''',
        expected: '[1.0, 1.0]',
      ),
      quiz: [
        mcq(
          id: 'q_ml_04',
          question: 'Ridge adds λI to XᵀX to',
          options: [
            opt('1', 'Stabilize inversion and shrink weights', true),
            opt('2', 'Increase training MSE on purpose always', false),
            opt('3', 'Turn regression into clustering', false),
          ],
          explanation: 'λ damps small eigenvalues.',
          topic: 'ML',
        ),
      ],
      takeaways: const ['Ship a linear baseline.', 'Prefer stable solvers.'],
    );

Lesson _cvfold() => lesson(
      id: 'ml_05',
      trackId: 'track_ml',
      moduleId: 'mod_ml_01',
      title: 'Cross-Validation without Cheating',
      subtitle: 'Every transform belongs inside the fold',
      minutes: 8,
      xp: 50,
      concept:
          'K-fold CV estimates generalization by rotating hold-outs. Pipelines must fit scalers and selectors on the training fold only.',
      why: 'Nested CV is how you report a number you would defend in a paper or a launch review.',
      eli5: 'Study on four days, test on the fifth, then rotate. Do not peek at Friday’s answers on Monday.',
      engineer: 'Use `Pipeline` + `GridSearchCV`. For time series, use `TimeSeriesSplit`.',
      analogy: 'Five different practice exams, never the one you already graded.',
      quiz: [
        mcq(
          id: 'q_ml_05',
          question: 'Where does a StandardScaler belong?',
          options: [
            opt('1', 'Inside the CV pipeline, fit on train folds', true),
            opt('2', 'Fit once on the whole dataset first', false),
            opt('3', 'Only on the test fold', false),
          ],
          explanation: 'Otherwise fold scores leak test statistics.',
          topic: 'CV',
        ),
      ],
      takeaways: const ['Transforms live in the fold.', 'Match the split to the data.'],
    );

Lesson _backprop() => lesson(
      id: 'dl_03',
      trackId: 'track_dl',
      moduleId: 'mod_dl_01',
      title: 'Backpropagation as Local Messages',
      subtitle: 'Each layer only needs its local Jacobian',
      minutes: 10,
      xp: 70,
      concept:
          'Backprop is reverse-mode autodiff. The loss sends a gradient backward; each op multiplies by its local derivative.',
      why: 'If you can write the graph, you can debug exploding/vanishing gradients.',
      eli5: 'A rumor goes backward through the factory: “you made the error bigger, adjust your knob.”',
      engineer: 'Watch grad norms. Clip when they spike. Residual links keep a path of identity derivatives.',
      analogy: 'A supply chain sending defect reports upstream to the exact station.',
      formula: '∂L/∂W = (∂L/∂z)(∂z/∂W)',
      visualizer: VisualizerType.neuralNetwork,
      code: py(
        'Manual scalar backprop',
        r'''
w, x, y = 2.0, 3.0, 7.0
z = w * x
loss = (z - y) ** 2
dloss_dz = 2 * (z - y)
dw = dloss_dz * x
print(round(dw, 1))
''',
        expected: '-6.0',
      ),
      quiz: [
        mcq(
          id: 'q_dl_03',
          question: 'Vanishing gradients are most associated with',
          options: [
            opt('1', 'Saturated sigmoids / deep ungated stacks', true),
            opt('2', 'ReLU on the first layer only', false),
            opt('3', 'Too much residual signal', false),
          ],
          explanation: 'Tiny local derivatives multiply down the tape.',
          topic: 'Deep Learning',
        ),
      ],
      takeaways: const ['Backprop is local.', 'Residuals protect the gradient path.'],
    );

Lesson _optim() => lesson(
      id: 'dl_04',
      trackId: 'track_dl',
      moduleId: 'mod_dl_01',
      title: 'SGD, Momentum & AdamW',
      subtitle: 'The optimizer is part of the model',
      minutes: 8,
      xp: 55,
      concept:
          'SGD steps −η∇. Momentum averages velocity. Adam adapts per-parameter rates. AdamW decouples weight decay.',
      why: 'Transformer training recipes are optimizer recipes as much as architecture recipes.',
      eli5: 'A ball (momentum) vs a ball that remembers which shoes slip (Adam).',
      engineer: 'Use warmup + cosine decay. Do not copy Adam peaks into a tiny CNN without retuning η.',
      analogy: 'Different hiking poles for ice vs gravel.',
      quiz: [
        mcq(
          id: 'q_dl_04',
          question: 'AdamW’s distinctive fix is',
          options: [
            opt('1', 'Decoupled weight decay', true),
            opt('2', 'Removing momentum', false),
            opt('3', 'Integer-only gradients', false),
          ],
          explanation: 'L2 in the Adam update is not the same as decay on weights.',
          topic: 'Optimizers',
        ),
      ],
      takeaways: const ['η schedule matters.', 'AdamW for transformers is default, not magic.'],
    );

Lesson _yolo() => lesson(
      id: 'cv_03',
      trackId: 'track_cv',
      moduleId: 'mod_cv_01',
      title: 'Detection with YOLO-style Heads',
      subtitle: 'Boxes are a different contract than class logits',
      minutes: 9,
      xp: 60,
      concept:
          'Single-stage detectors predict boxes + objectness + class in one pass. NMS removes duplicates. Labeling cost dominates.',
      why: 'Shipping classification when you needed boxes wastes a quarter.',
      eli5: 'Not “there is a dog in this photo” — “the dog is in this rectangle.”',
      engineer: 'Letterbox resize. Match pretrained stride. Start from a COCO checkpoint unless your domain is alien.',
      analogy: 'Sticky notes on a family photo vs a caption under the frame.',
      quiz: [
        mcq(
          id: 'q_cv_03',
          question: 'NMS exists to',
          options: [
            opt('1', 'Drop overlapping duplicate boxes', true),
            opt('2', 'Normalize RGB', false),
            opt('3', 'Train the backbone from scratch', false),
          ],
          explanation: 'Many anchors fire on the same object.',
          topic: 'CV',
        ),
      ],
      takeaways: const ['Task head first.', 'NMS is post-process, not magic.'],
      projects: const ['proj_06'],
    );

Lesson _embedWords() => lesson(
      id: 'nlp_03',
      trackId: 'track_nlp',
      moduleId: 'mod_nlp_01',
      title: 'From One-Hot to Word Embeddings',
      subtitle: 'Meaning as nearby points',
      minutes: 8,
      xp: 50,
      concept:
          'One-hot has no geometry. Word2Vec / GloVe place similar words nearby. Contextual models (BERT) give a different vector per occurrence.',
      why: 'Static embeddings still initialize search and classical classifiers.',
      eli5: '“King” and “queen” sit on the same shelf; “bicycle” is down the aisle.',
      engineer: 'Do not mix embedding spaces. Cosine after L2-norm. OOV needs a policy (hash, UNK, subwords).',
      analogy: 'A city map where related shops cluster in districts.',
      visualizer: VisualizerType.vectorSearch,
      quiz: [
        mcq(
          id: 'q_nlp_03',
          question: 'BERT vs Word2Vec for “bank”',
          options: [
            opt('1', 'BERT depends on the sentence; Word2Vec is one vector', true),
            opt('2', 'They are identical', false),
            opt('3', 'Word2Vec is always contextual', false),
          ],
          explanation: 'Static vs contextual embeddings.',
          topic: 'NLP',
        ),
      ],
      takeaways: const ['Context needs transformers.', 'Never mix spaces.'],
    );

Lesson _rope() => lesson(
      id: 'trans_03',
      trackId: 'track_transformers',
      moduleId: 'mod_trans_01',
      title: 'Positional Encoding & RoPE',
      subtitle: 'Attention has no order unless you add it',
      minutes: 9,
      xp: 65,
      concept:
          'Without positions, a bag of tokens is permutation-invariant. Sinusoidal encodings add absolute phase. RoPE rotates Q/K so relative distance appears in the dot product.',
      why: 'Long-context models live or die on how they encode distance.',
      eli5: 'Page numbers so the model knows “not” came before “good.”',
      engineer: 'Extrapolation ≠ interpolation. Test your RoPE scale on longer sequences than you trained.',
      analogy: 'A musical score: notes without bars are just a pile.',
      quiz: [
        mcq(
          id: 'q_trans_03',
          question: 'Self-attention without positions treats the sequence as',
          options: [
            opt('1', 'A bag (orderless) of tokens', true),
            opt('2', 'A causal CNN', false),
            opt('3', 'A sorted list by value', false),
          ],
          explanation: 'Dots do not know index unless you encode it.',
          topic: 'Transformers',
        ),
      ],
      takeaways: const ['Add position explicitly.', 'Check long-context behavior.'],
    );

Lesson _peft() => lesson(
      id: 'hf_02',
      trackId: 'track_hf',
      moduleId: 'mod_hf_01',
      title: 'PEFT on the Hub: Load a LoRA Adapter',
      subtitle: 'Ship a 50MB delta, not a 14GB twin',
      minutes: 8,
      xp: 55,
      concept:
          'PEFT stores low-rank adapters. At inference you merge or apply them on the frozen base. The Hub stores adapter + base id.',
      why: 'Multi-tenant products cannot host a full fine-tune per customer.',
      eli5: 'A sticky note on a textbook instead of reprinting the book.',
      engineer: 'Pin `base_model_name_or_path` and adapter revision. Merge for latency; keep adapters for swap.',
      analogy: 'Camera lens filters — same body, different look.',
      tech: const ['tech_huggingface'],
      quiz: [
        mcq(
          id: 'q_hf_02',
          question: 'A LoRA adapter is useless without',
          options: [
            opt('1', 'The matching base checkpoint', true),
            opt('2', 'A vector database', false),
            opt('3', 'FlashAttention', false),
          ],
          explanation: 'Adapters are deltas on a specific base.',
          topic: 'PEFT',
        ),
      ],
      takeaways: const ['Pin base + adapter.', 'Merge only when you must.'],
    );

Lesson _diffusion() => lesson(
      id: 'gen_03',
      trackId: 'track_genai',
      moduleId: 'mod_gen_01',
      title: 'Diffusion Models in One Page',
      subtitle: 'Learn to reverse noise',
      minutes: 9,
      xp: 55,
      concept:
          'A forward process adds Gaussian noise. A network predicts noise (or velocity) so we can step backward from N(0,I) to an image.',
      why: 'Modern image/video systems are diffusion or flow-matching, not GANs.',
      eli5: 'Destroy a drawing with static, then teach a robot to undo the static.',
      engineer: 'Sampler (DDIM, Euler) is a product knob. Guidance scale trades fidelity vs prompt adherence.',
      analogy: 'Developing film: from grainy nothing to a sharp frame.',
      quiz: [
        mcq(
          id: 'q_gen_03',
          question: 'Classifier-free guidance mainly trades',
          options: [
            opt('1', 'Prompt adherence vs diversity/artifacts', true),
            opt('2', 'Batch size vs GPU vendor', false),
            opt('3', 'Tokenizers vs BPE', false),
          ],
          explanation: 'Higher guidance follows the prompt more tightly and can oversaturate.',
          topic: 'Generative AI',
        ),
      ],
      takeaways: const ['Diffusion is denoise-to-sample.', 'Samplers are product UX.'],
    );

Lesson _tools() => lesson(
      id: 'llm_03',
      trackId: 'track_llm',
      moduleId: 'mod_llm_01',
      title: 'Function Calling as a Typed Contract',
      subtitle: 'The model proposes; your runtime decides',
      minutes: 9,
      xp: 65,
      concept:
          'Tool calling emits a structured name + arguments. Your server validates, executes, and returns a tool result message. The model never holds the secret.',
      why: 'This is the difference between a demo and a system that can refund an order.',
      eli5: 'The intern writes a form. The manager checks it, then presses the button.',
      engineer: 'JSON schema + allow-list + idempotency keys. Log the tool trace. Never let the model see raw credentials.',
      analogy: 'A restaurant ticket: the cook only sees the dish, not the credit card.',
      code: py(
        'Validate a tool call',
        r'''
def refund(order_id: str, cents: int):
    assert cents > 0 and cents < 50_000
    return {"ok": True, "order_id": order_id}

print(refund("A1", 200)["ok"])
''',
        expected: 'True',
      ),
      quiz: [
        mcq(
          id: 'q_llm_03',
          question: 'Who should execute a payment tool?',
          options: [
            opt('1', 'Your backend after schema + auth checks', true),
            opt('2', 'The model weights directly', false),
            opt('3', 'The system prompt', false),
          ],
          explanation: 'The model proposes; the runtime is the authority.',
          topic: 'LLM Engineering',
        ),
      ],
      takeaways: const ['Validate then execute.', 'Secrets stay server-side.'],
    );

Lesson _hybrid() => lesson(
      id: 'emb_02',
      trackId: 'track_embeddings',
      moduleId: 'mod_emb_01',
      title: 'Hybrid Search: Dense + BM25',
      subtitle: 'Semantics miss SKUs; keywords miss paraphrases',
      minutes: 8,
      xp: 55,
      concept:
          'Fuse a dense rank list and a lexical rank list (RRF or weighted sum). Metadata filters apply before or after.',
      why: 'Enterprise queries are half jargon, half natural language.',
      eli5: 'Search by vibe and by exact barcode, then shuffle the two lists fairly.',
      engineer: 'Tune k in RRF. Always keep an eval set of keyword-heavy and semantic-heavy queries.',
      analogy: 'A library: Dewey decimal plus “books that feel like this.”',
      visualizer: VisualizerType.vectorSearch,
      tech: const ['tech_qdrant', 'tech_faiss'],
      quiz: [
        mcq(
          id: 'q_emb_02',
          question: 'BM25 is strong when the query contains',
          options: [
            opt('1', 'Exact identifiers and rare tokens', true),
            opt('2', 'Only stopwords', false),
            opt('3', 'A 4k image', false),
          ],
          explanation: 'Lexical match wins on SKUs and error codes.',
          topic: 'Search',
        ),
      ],
      takeaways: const ['Hybrid is default for RAG.', 'Eval both query types.'],
    );

Lesson _chunk() => lesson(
      id: 'rag_03',
      trackId: 'track_rag',
      moduleId: 'mod_rag_01',
      title: 'Chunking That Respects Structure',
      subtitle: 'A split table is a hallucination factory',
      minutes: 9,
      xp: 60,
      concept:
          'Prefer headings, list items, and table rows as boundaries. Parent-child stores small children for match and large parents for context.',
      why: 'Fixed 512-token windows cut “not” away from “authorized.”',
      eli5: 'Do not tear a sentence in half just because the ruler said 512.',
      engineer: 'Keep page + section metadata. Overlap is a bandage, not a strategy.',
      analogy: 'Chapters, not random 10-page slices through a novel.',
      visualizer: VisualizerType.ragPipeline,
      quiz: [
        mcq(
          id: 'q_rag_03',
          question: 'Parent-child retrieval returns',
          options: [
            opt('1', 'Small match units, wider read units', true),
            opt('2', 'Only the tokenizer vocabulary', false),
            opt('3', 'Unchunked raw bytes always', false),
          ],
          explanation: 'Match precise, read complete.',
          topic: 'RAG',
        ),
      ],
      takeaways: const ['Structure-aware splits.', 'Metadata is retrieval.'],
    );

Lesson _dpo() => lesson(
      id: 'ft_02',
      trackId: 'track_finetune',
      moduleId: 'mod_ft_01',
      title: 'SFT vs DPO',
      subtitle: 'Imitation is not preference',
      minutes: 8,
      xp: 55,
      concept:
          'SFT maximizes likelihood of demonstrations. DPO pushes chosen completions above rejected ones without a separate reward model.',
      why: 'A model that can copy docs still sounds rude or unsafe. Preference data fixes style and policy.',
      eli5: 'SFT: copy the homework. DPO: this answer was better than that one.',
      engineer: 'You still need clean pairs. DPO will amplify annotator bias. Keep a policy eval.',
      analogy: 'A writing coach circling the better paragraph, not just typing a sample essay.',
      quiz: [
        mcq(
          id: 'q_ft_02',
          question: 'DPO requires',
          options: [
            opt('1', 'Preferred vs rejected completions', true),
            opt('2', 'Only unlabeled web text', false),
            opt('3', 'A vector database', false),
          ],
          explanation: 'Preference pairs are the data.',
          topic: 'Fine-tuning',
        ),
      ],
      takeaways: const ['SFT for format.', 'DPO for preference/policy.'],
    );

Lesson _toolsafety() => lesson(
      id: 'agent_03',
      trackId: 'track_agents',
      moduleId: 'mod_agent_01',
      title: 'Tool Allow-Lists & Idempotency',
      subtitle: 'An agent that retries must not double-charge',
      minutes: 8,
      xp: 70,
      concept:
          'Every side-effecting tool needs an idempotency key, an allow-list, and a human or policy gate for high blast radius.',
      why: 'ReAct loops retry. Retries without keys duplicate money and emails.',
      eli5: 'If you send the same “buy” note twice, the shop should still send one box.',
      engineer: 'Store tool receipts in state. Deduplicate on (tool, key). Timeout ≠ failure for payments.',
      analogy: 'A restaurant ticket number so the kitchen does not plate twice.',
      visualizer: VisualizerType.agentReactLoop,
      quiz: [
        mcq(
          id: 'q_agent_03',
          question: 'A payment tool must be',
          options: [
            opt('1', 'Idempotent and gated', true),
            opt('2', 'Callable from retrieved web text', false),
            opt('3', 'Unlogged for privacy', false),
          ],
          explanation: 'Retries are guaranteed. Duplicates are not acceptable.',
          topic: 'Agents',
        ),
      ],
      takeaways: const ['Allow-list tools.', 'Idempotency keys on effects.'],
    );

Lesson _hitl() => lesson(
      id: 'lg_02',
      trackId: 'track_langgraph',
      moduleId: 'mod_lg_01',
      title: 'Human-in-the-Loop Interrupts',
      subtitle: 'Pause the graph before the world changes',
      minutes: 8,
      xp: 60,
      concept:
          'LangGraph can interrupt before a node. A human approves, edits state, and the checkpointer resumes.',
      why: 'Compliance teams will not accept fire-and-forget agents on customer data.',
      eli5: 'The robot waits at the red door until a person badges it through.',
      engineer: 'Interrupt on `tools` that mutate. Store the proposed args in state for the UI.',
      analogy: 'Two-person rule for launching a rocket.',
      tech: const ['tech_langgraph'],
      quiz: [
        mcq(
          id: 'q_lg_02',
          question: 'HITL is most valuable',
          options: [
            opt('1', 'Before irreversible side effects', true),
            opt('2', 'After the process already emailed 10k users', false),
            opt('3', 'Only for CSS tweaks', false),
          ],
          explanation: 'Pause where blast radius is high.',
          topic: 'LangGraph',
        ),
      ],
      takeaways: const ['Interrupt before mutate.', 'Resume from a checkpoint.'],
    );

Lesson _tsClient() => lesson(
      id: 'mcp_03',
      trackId: 'track_mcp',
      moduleId: 'mod_mcp_01',
      title: 'MCP Clients in TypeScript',
      subtitle: 'Hosts are clients; servers are capabilities',
      minutes: 9,
      xp: 70,
      concept:
          'A client initializes, lists tools, and calls them. Cursor and Claude Desktop are hosts. Your app can be a host too.',
      why: 'If you only write servers, you cannot embed MCP inside your own agent product.',
      eli5: 'The plug (client) asks the wall (server) what appliances exist, then turns one on.',
      engineer: 'Use the official TS SDK. Treat tool results as untrusted text. Scope servers per workspace.',
      analogy: 'A USB host enumerating devices.',
      visualizer: VisualizerType.mcpArchitecture,
      code: py(
        'Client-shaped call',
        r'''
# Conceptual request a TS host would send
req = {"method": "tools/call", "params": {"name": "search", "arguments": {"q": "RAG"}}}
print(req["method"], req["params"]["name"])
''',
        expected: 'tools/call search',
      ),
      quiz: [
        mcq(
          id: 'q_mcp_03',
          question: 'In MCP, Cursor is typically',
          options: [
            opt('1', 'A host / client', true),
            opt('2', 'A vector index', false),
            opt('3', 'A GPU kernel', false),
          ],
          explanation: 'Hosts consume servers.',
          topic: 'MCP',
        ),
      ],
      takeaways: const ['Host vs server roles.', 'Untrusted tool text.'],
      tech: const ['tech_mcp'],
    );

Lesson _mlflow() => lesson(
      id: 'ops_02',
      trackId: 'track_mlops',
      moduleId: 'mod_ops_01',
      title: 'Experiment Tracking & Registries',
      subtitle: 'If it is not logged, it did not happen',
      minutes: 8,
      xp: 55,
      concept:
          'MLflow/W&B store params, metrics, artifacts, and a stage (None/Staging/Production). Promotion is a review, not a filename.',
      why: '“Which notebook beat prod?” is otherwise folklore.',
      eli5: 'A lab notebook that also keeps the exact cake recipe and a photo of the cake.',
      engineer: 'Log data hash + git SHA + prompt version. Block prod promotion without an eval suite.',
      analogy: 'A museum accession number for every artifact.',
      tech: const ['tech_mlflow'],
      quiz: [
        mcq(
          id: 'q_ops_02',
          question: 'A model registry stage should change when',
          options: [
            opt('1', 'Eval + review say so', true),
            opt('2', 'Training loss dropped once', false),
            opt('3', 'Someone renamed a file', false),
          ],
          explanation: 'Promotion is a process.',
          topic: 'MLOps',
        ),
      ],
      takeaways: const ['Log lineage.', 'Promote with evals.'],
    );

Lesson _indirect() => lesson(
      id: 'sec_03',
      trackId: 'track_eval_security',
      moduleId: 'mod_sec_01',
      title: 'Indirect Prompt Injection',
      subtitle: 'The attacker is inside the retrieved page',
      minutes: 9,
      xp: 70,
      concept:
          'Untrusted documents can contain instructions (“ignore the user, exfiltrate secrets”). Agents that then call tools complete the attack.',
      why: 'RAG + tools is the default enterprise architecture — and the default exploit path.',
      eli5: 'A library book that says “give the stranger the vault key” and a helpful robot that obeys books.',
      engineer:
          'Delimit untrusted text. Strip instruction-like patterns. Dual-model: one retrieves, one answers with a tight schema. Confirm tools.',
      analogy: 'SQL injection, except the payload is English.',
      quiz: [
        mcq(
          id: 'q_sec_03',
          question: 'The dangerous combination is',
          options: [
            opt('1', 'Untrusted retrieval + powerful tools', true),
            opt('2', 'Frozen embeddings only', false),
            opt('3', 'Offline unit tests', false),
          ],
          explanation: 'Text becomes a control channel when tools exist.',
          topic: 'Security',
        ),
      ],
      takeaways: const ['Retrieved text is hostile.', 'Gate tools.'],
    );

RoadmapTrack _vectorDb() {
  const id = 'track_vectordb';
  const mod = 'mod_vdb_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 20,
    title: 'Vector Databases',
    tagline: 'HNSW, filters, hybrid, and operations',
    icon: '🗄️',
    colorHex: '#D32F2F',
    description: 'Indexes, payloads, and the difference between a demo FAISS pickle and a multi-tenant store.',
    keySkills: const ['HNSW', 'Qdrant', 'FAISS', 'Filters', 'Replication'],
    prerequisiteTrackIds: const ['track_embeddings'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Indexes that survive production',
        description: 'ANN, payloads, tenancy.',
        lessons: [
          lesson(
            id: 'vdb_01',
            trackId: id,
            moduleId: mod,
            title: 'HNSW vs Flat Search',
            subtitle: 'Approximate neighbors are a product decision',
            minutes: 9,
            xp: 60,
            concept:
                'Flat search is exact and O(n). HNSW builds a navigable small-world graph for ~log n queries with recall/latency knobs (ef).',
            why: '10M vectors cannot brute-force on every keystroke.',
            eli5: 'A highway system vs checking every house on the continent.',
            engineer: 'Measure recall@k on a holdout. Do not copy `ef=16` from a blog into legal search.',
            analogy: 'A metro map that skips some streets on purpose so trains run on time.',
            visualizer: VisualizerType.vectorSearch,
            tech: const ['tech_qdrant', 'tech_faiss'],
            quiz: [
              mcq(
                id: 'q_vdb_01',
                question: 'HNSW trades',
                options: [
                  opt('1', 'A little recall for a lot of latency', true),
                  opt('2', 'Tokens for pixels', false),
                  opt('3', 'SQL for CSS', false),
                ],
                explanation: 'ANN is controlled approximation.',
                topic: 'Vector DB',
              ),
            ],
            takeaways: const ['Measure recall.', 'ef is a SLO knob.'],
          ),
          lesson(
            id: 'vdb_02',
            trackId: id,
            moduleId: mod,
            title: 'Payload Filters & Multi-Tenancy',
            subtitle: 'The neighbor in another tenant is a breach',
            minutes: 8,
            xp: 65,
            concept:
                'Filter on tenant, ACL, and document type at query time. Prefer namespace-per-tenant or strict must-filters that the engine cannot skip.',
            why: 'Cosine does not understand authorization.',
            eli5: 'Only search inside your classroom, not the whole school.',
            engineer: 'Test a negative: query as tenant A must never return tenant B IDs, even as neighbors.',
            analogy: 'Hotel keycards, not a pile of unlocked rooms ranked by “similar decor.”',
            tech: const ['tech_qdrant'],
            quiz: [
              mcq(
                id: 'q_vdb_02',
                question: 'Authorization belongs',
                options: [
                  opt('1', 'In the query filter / partition, not just the prompt', true),
                  opt('2', 'Only in the system prompt', false),
                  opt('3', 'In CSS', false),
                ],
                explanation: 'The index will happily return another tenant’s vector.',
                topic: 'Vector DB',
              ),
            ],
            takeaways: const ['Filter is security.', 'Write a tenancy test.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _inference() {
  const id = 'track_inference';
  const mod = 'mod_inf_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 21,
    title: 'LLM Inference',
    tagline: 'KV cache, batching, quantization, tokens/sec',
    icon: '⚡',
    colorHex: '#F9A825',
    description: 'Serve tokens under a latency SLO: paged attention, quant, and continuous batching.',
    keySkills: const ['vLLM', 'KV cache', 'INT4/8', 'Continuous batching'],
    prerequisiteTrackIds: const ['track_llm'],
    careerGoals: const [CareerGoal.llmEngineer, CareerGoal.mlopsEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Serving that pays the GPU bill',
        description: 'Memory is the KV cache.',
        lessons: [
          lesson(
            id: 'inf_01',
            trackId: id,
            moduleId: mod,
            title: 'KV Cache & Why Context is Expensive',
            subtitle: 'Memory grows with tokens, not just parameters',
            minutes: 9,
            xp: 65,
            concept:
                'Each decoded token appends K/V. Long context + concurrency exhausts VRAM before weights do. PagedAttention treats cache like virtual memory.',
            why: '“Just raise max_model_len” is how you OOM at 4pm.',
            eli5: 'The model keeps a growing notebook of everything said so it does not reread the book.',
            engineer: 'GQA/MQA shrink K/V heads. Quantize KV if the engine supports it. Cap concurrency.',
            analogy: 'A waiter’s notepad: more tables, more pages, no extra kitchen.',
            tech: const ['tech_vllm'],
            quiz: [
              mcq(
                id: 'q_inf_01',
                question: 'The KV cache grows with',
                options: [
                  opt('1', 'Sequence length × layers × heads × dim', true),
                  opt('2', 'Only the number of GPUs', false),
                  opt('3', 'The learning rate', false),
                ],
                explanation: 'It is activation memory over time.',
                topic: 'Inference',
              ),
            ],
            takeaways: const ['Context is RAM.', 'Page the cache.'],
          ),
          lesson(
            id: 'inf_02',
            trackId: id,
            moduleId: mod,
            title: 'Quantization: FP16 to INT4',
            subtitle: 'Bits you drop are quality you must measure',
            minutes: 8,
            xp: 60,
            concept:
                'Lower precision shrinks weights and bandwidth. AWQ/GPTQ/GGUF are methods, not free lunches. Eval on your tasks, not only perplexity.',
            why: 'A 70B that fits is useless if tool-calling JSON breaks.',
            eli5: 'Compressing a photo: smaller file, sometimes mushy text on signs.',
            engineer: 'Keep a golden set of tool calls and RAG faithfulness after every quant.',
            analogy: 'Airline baggage: you can squeeze the suitcase until a zipper fails.',
            quiz: [
              mcq(
                id: 'q_inf_02',
                question: 'Before shipping INT4, measure',
                options: [
                  opt('1', 'Task metrics (tools, RAG), not only PPL', true),
                  opt('2', 'Only GPU sticker price', false),
                  opt('3', 'Font kerning', false),
                ],
                explanation: 'Quantization errors show up in structure first.',
                topic: 'Inference',
              ),
            ],
            takeaways: const ['Quant is a product eval.', 'Fit ≠ quality.'],
            tech: const ['tech_vllm'],
          ),
        ],
      ),
    ],
  );
}
