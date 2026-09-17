import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import 'lesson_factory.dart';

List<RoadmapTrack> foundationTracks() => [
      _python(),
      _math(),
      _dataScience(),
      _machineLearning(),
      _deepLearning(),
      _computerVision(),
    ];

RoadmapTrack _python() {
  const id = 'track_python';
  const mod = 'mod_py_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 0,
    title: 'Python',
    tagline: 'From your first program to concurrency, packaging, and a capstone',
    icon: 'PY',
    colorHex: '#3776AB',
    description:
        'Python 3 from first principles: setup, types, strings, control flow, collections, functions, files, errors, OOP, modules, and advanced topics — 10 modules with a quiz and exercise in every lesson.',
    keySkills: const ['Python 3', 'OOP', 'Error handling', 'Iterators & generators', 'Concurrency'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Modern Python & Vectorized Thinking',
        description: 'Core syntax, memory-efficient scientific computing, and APIs.',
        lessons: [
          lesson(
            id: 'py_01',
            trackId: id,
            moduleId: mod,
            title: 'Vectorized Operations with NumPy',
            subtitle: 'Why Python loops fail and how broadcasting accelerates AI',
            minutes: 8,
            xp: 50,
            concept:
                'In AI, processing millions of floats in Python for-loops bottlenecks on dynamic typing. NumPy allocates contiguous C-memory arrays and uses SIMD registers so one instruction updates many values.',
            why:
                'Every model — from linear regression to a 405B LLM — is tensor arithmetic. Memory layout and broadcasting are prerequisites for PyTorch and JAX.',
            eli5:
                'Packing 1,000 apples one-by-one is slow. NumPy is a conveyor belt that loads all 1,000 in one motion.',
            engineer:
                'ndarrays store homogeneous data with fixed strides. Vectorized ops bypass the GIL and run compiled BLAS/Fortran kernels in L1/L2 cache.',
            analogy: 'Translating a book word-by-word versus translating whole paragraphs at once.',
            formula: 'C = A ⊙ B   where  c_ij = a_ij · b_ij',
            mathIntuition: 'Element-wise ops need matching shapes or broadcast-compatible trailing axes.',
            visualizer: VisualizerType.vectorSearch,
            code: py(
              'NumPy broadcasting',
              r'''
import numpy as np

a = np.random.randn(4, 1)
b = np.random.randn(1, 3)
c = a * b
print("Result shape:", c.shape)
print("Mean:", round(float(c.mean()), 4))
''',
              explanation: 'A (4,1) broadcasts with B (1,3) into (4,3) without copying rows/cols.',
              expected: 'Result shape: (4, 3)\nMean: -0.0124',
            ),
            mistakes: const [
              'Using Python loops over arrays instead of vectorized expressions.',
              'Copying arrays when a view (slice) is enough.',
              'Ignoring axis orientation in reductions.',
            ],
            interview: interview(
              question: 'What is array broadcasting and what are the compatibility rules?',
              answer:
                  'Broadcasting lets NumPy operate on different shapes. Axes are compatible when they are equal or one of them is 1, compared from the trailing side.',
              followUps: const ['How does contiguous layout affect CUDA cache locality?'],
              terms: const ['Broadcasting', 'Strides', 'SIMD'],
              topic: 'Python',
            ),
            quiz: [
              mcq(
                id: 'q_py_01',
                question: 'Shape of A (4×1×8) broadcast with B (3×8)?',
                options: [
                  opt('1', '4 × 3 × 8', true, '8 matches 8, 1→3, 4 prepends.'),
                  opt('2', '4 × 1 × 8', false),
                  opt('3', 'Shape mismatch', false),
                  opt('4', '12 × 8', false),
                ],
                explanation: 'Trailing axes: 8==8, 1 broadcasts to 3, leading 4 is kept.',
                topic: 'NumPy',
              ),
            ],
            takeaways: const [
              'Vectorize mathematical transforms.',
              'NumPy arrays are C-contiguous and cache-friendly.',
              'Broadcasting aligns dimensions without duplicating memory.',
            ],
            tech: const ['tech_numpy'],
          ),
          lesson(
            id: 'py_02',
            trackId: id,
            moduleId: mod,
            title: 'Dataclasses, Type Hints & Structured Data',
            subtitle: 'Make training configs and model cards unambiguous',
            minutes: 7,
            xp: 45,
            concept:
                'Type hints and dataclasses turn ad-hoc dictionaries into validated, self-documenting objects — the same idea as Pydantic models in FastAPI.',
            why:
                'Production AI code fails more often from mis-shaped payloads than from bad math. Types catch that before a 4-hour training run.',
            eli5:
                'A lunchbox with labeled compartments beats a grocery bag. You always know where the apple is.',
            engineer:
                'Use `@dataclass(frozen=True)` for configs, `TypedDict` for state, and `Protocol` for interchangeable model backends.',
            analogy: 'Shipping labels on crates versus unmarked boxes on a warehouse floor.',
            code: py(
              'Training config',
              r'''
from dataclasses import dataclass

@dataclass(frozen=True)
class TrainConfig:
    lr: float = 3e-4
    batch_size: int = 32
    epochs: int = 10

cfg = TrainConfig(lr=1e-4)
print(cfg)
print("Immutable:", cfg.batch_size)
''',
              expected: "TrainConfig(lr=0.0001, batch_size=32, epochs=10)\nImmutable: 32",
            ),
            mistakes: const ['Mutable global configs', 'Stringly-typed hyperparameters'],
            quiz: [
              mcq(
                id: 'q_py_02',
                question: 'Why freeze a dataclass used as a training config?',
                options: [
                  opt('1', 'Prevents accidental mutation mid-run', true),
                  opt('2', 'Makes NumPy faster', false),
                  opt('3', 'Required by the GIL', false),
                ],
                explanation: 'Frozen configs are hashable and safe to share across workers.',
                topic: 'Python',
              ),
            ],
            takeaways: const ['Prefer typed configs over loose dicts.', 'Immutability prevents silent drift.'],
          ),
          lesson(
            id: 'py_03',
            trackId: id,
            moduleId: mod,
            title: 'Async Python for Model APIs',
            subtitle: 'Concurrency without blocking inference I/O',
            minutes: 9,
            xp: 55,
            concept:
                'AsyncIO lets a single process await network I/O — token streams, embedding APIs, vector DBs — without blocking other requests.',
            why: 'LLM apps are I/O bound. Blocking FastAPI routes waste GPUs waiting on HTTP.',
            eli5: 'A chef who starts rice, then chops vegetables, instead of staring at the pot.',
            engineer:
                'Use `async def` for I/O, thread/process pools for CPU-bound tokenization, and never block the event loop with `time.sleep`.',
            analogy: 'A restaurant ticket rail versus one waiter who only serves one table.',
            code: py(
              'Async gather',
              r'''
import asyncio

async def embed(text: str) -> int:
    await asyncio.sleep(0)
    return len(text)

async def main():
    sizes = await asyncio.gather(embed("RAG"), embed("MCP"))
    print(sizes)

asyncio.run(main())
''',
              expected: '[3, 3]',
            ),
            takeaways: const ['Await I/O, isolate CPU work.', 'Streaming tokens is an async problem.'],
            tech: const ['tech_fastapi'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _math() {
  const id = 'track_math';
  const mod = 'mod_math_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 1,
    title: 'Mathematics for AI',
    tagline: 'Vectors, calculus, probability & statistics — the math behind ML',
    icon: 'Σ',
    colorHex: '#5C6BC0',
    description:
        'The math that actually shows up in models, explained simply: vectors and matrices, eigenvectors, derivatives and gradient descent, probability, and the statistics behind A/B tests.',
    keySkills: const ['Vectors & Matrices', 'Eigenvectors', 'Gradient Descent', 'Probability', 'Statistics'],
    prerequisiteTrackIds: const ['track_python'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Calculus & Optimization',
        description: 'How networks compute loss gradients and update weights.',
        lessons: [
          lesson(
            id: 'math_01',
            trackId: id,
            moduleId: mod,
            title: 'Gradient Descent & Loss Optimization',
            subtitle: 'Navigating a loss landscape one honest step at a time',
            minutes: 10,
            xp: 60,
            concept:
                'Gradient descent iteratively minimizes a differentiable loss. ∇L(w) points uphill; a step in the opposite direction reduces error.',
            why:
                'Every modern network learns by computing ∂L/∂θ and stepping with SGD, Adam, or AdamW.',
            eli5:
                'Blindfolded on a foggy hill, you feel the slope and take a small step downhill. Repeat until the ground flattens.',
            engineer:
                'w_{t+1} = w_t − η ∇L(w_t). AdamW keeps EMA of first/second moments and decouples weight decay from the gradient step.',
            analogy: 'A marble rolling inside a bowl until it rests at the bottom.',
            formula: 'w_{t+1} = w_t − η · ∂L/∂w',
            mathIntuition: 'The derivative is instantaneous slope. Subtracting it walks toward lower error.',
            visualizer: VisualizerType.gradientDescent,
            code: py(
              '1D gradient descent',
              r'''
def loss(w): return (w - 3) ** 2
def grad(w): return 2 * (w - 3)

w, lr = 10.0, 0.1
for _ in range(25):
    w = w - lr * grad(w)
print(f"w={w:.4f}  L={loss(w):.6f}")
''',
              explanation: 'Quadratic bowl with minimum at w*=3.',
              expected: 'w=3.0027  L=0.000007',
            ),
            mistakes: const [
              'Learning rate too large → divergence / NaNs.',
              'Learning rate too small → apparent freeze.',
              'Treating every minimum as global in non-convex nets.',
            ],
            interview: interview(
              question: 'Why is AdamW usually preferred over vanilla SGD for Transformers?',
              answer:
                  'Adam adapts per-parameter rates via first/second moments. AdamW decouples weight decay so regularization stays consistent across sparse and dense parameters.',
              followUps: const ['What does a warmup schedule prevent?'],
              terms: const ['AdamW', 'Learning rate', 'Weight decay'],
              topic: 'Mathematics',
            ),
            quiz: [
              mcq(
                id: 'q_math_01',
                question: 'What happens if η is far too large?',
                options: [
                  opt('1', 'The step overshoots and loss can diverge', true),
                  opt('2', 'It always finds the global minimum faster', false),
                  opt('3', 'Weights freeze at zero', false),
                ],
                explanation: 'Overshooting increases |∇L| on the far slope and can explode.',
                topic: 'Optimization',
              ),
            ],
            takeaways: const [
              'Gradient = vector of partial derivatives.',
              'η is step size along −∇L.',
              'Momentum damps oscillation in ravines.',
            ],
          ),
          lesson(
            id: 'math_02',
            trackId: id,
            moduleId: mod,
            title: 'Vectors, Dot Products & Projections',
            subtitle: 'The geometry behind attention and embeddings',
            minutes: 8,
            xp: 50,
            concept:
                'A vector is magnitude + direction. The dot product a·b = ||a|| ||b|| cosθ measures alignment — the same idea as cosine similarity.',
            why: 'Attention scores, embedding search, and PCA are all geometric products in disguise.',
            eli5: 'Two arrows pointing the same way have a big “same-direction” score. Opposite arrows score negative.',
            engineer:
                'Normalize embeddings if you want cosine. Unnormalized dots mix magnitude (document length) with meaning.',
            analogy: 'Wind aligning two weather vanes versus fighting them apart.',
            formula: 'cosθ = (a · b) / (||a|| ||b||)',
            mathIntuition: 'Divide out length so only angle remains.',
            visualizer: VisualizerType.vectorSearch,
            code: py(
              'Cosine similarity',
              r'''
import math

def cosine(a, b):
    dot = sum(x*y for x, y in zip(a, b))
    na = math.sqrt(sum(x*x for x in a))
    nb = math.sqrt(sum(y*y for y in b))
    return dot / (na * nb)

print(round(cosine([1, 0], [0.9, 0.1]), 4))
''',
              expected: '0.9939',
            ),
            takeaways: const ['Dot product = alignment.', 'Cosine ignores vector length.'],
            tech: const ['tech_numpy'],
          ),
          lesson(
            id: 'math_03',
            trackId: id,
            moduleId: mod,
            title: 'Bayes Theorem for Machine Learning',
            subtitle: 'Updating beliefs when new evidence arrives',
            minutes: 8,
            xp: 50,
            concept:
                'P(H|E) = P(E|H)P(H) / P(E). Posterior = likelihood × prior, normalized by evidence.',
            why: 'Naive Bayes, calibration, and many uncertainty estimates are Bayesian updates.',
            eli5:
                'You thought it might rain (prior). You see dark clouds (evidence). You update how sure you are.',
            engineer:
                'In classification, class priors matter when labels are imbalanced. Calibration plots reveal when softmax ≠ probability.',
            analogy: 'A doctor revising a diagnosis after a lab result.',
            formula: 'P(H|E) = P(E|H)P(H) / P(E)',
            quiz: [
              mcq(
                id: 'q_math_03',
                question: 'What does the posterior represent?',
                options: [
                  opt('1', 'Belief in H after seeing evidence', true),
                  opt('2', 'The learning rate', false),
                  opt('3', 'A dropout mask', false),
                ],
                explanation: 'Posterior is the updated distribution over hypotheses.',
                topic: 'Probability',
              ),
            ],
            takeaways: const ['Priors matter under imbalance.', 'Likelihood is P(data | hypothesis).'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _dataScience() {
  const id = 'track_ds';
  const mod = 'mod_ds_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 2,
    title: 'Data Science Fundamentals',
    tagline: 'Pandas, cleaning, features, EDA, and honest evaluation',
    icon: '🐼',
    colorHex: '#00838F',
    description:
        'The real day-to-day of data science, explained simply: pandas basics, cleaning messy data, engineering features, exploring with charts, and avoiding leakage.',
    keySkills: const ['Pandas', 'Data cleaning', 'Feature engineering', 'EDA', 'Avoiding leakage'],
    prerequisiteTrackIds: const ['track_python', 'track_math'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'From raw tables to trustworthy splits',
        description: 'The unglamorous work that decides whether a model is real.',
        lessons: [
          lesson(
            id: 'ds_01',
            trackId: id,
            moduleId: mod,
            title: 'Train / Validation / Test — and Leakage',
            subtitle: 'The most expensive bug in applied ML',
            minutes: 9,
            xp: 55,
            concept:
                'Train fits parameters, validation selects them, test estimates generalization. Leakage is any test-time information that sneaked into training.',
            why: 'A 99% demo that used future timestamps will fail in production on day one.',
            eli5: 'Studying with the answer key taped to the page is not learning.',
            engineer:
                'Fit scalers and target encoders on train only. Split by time or group when rows are not i.i.d.',
            analogy: 'A practice exam that accidentally includes tomorrow’s questions.',
            code: py(
              'Honest split',
              r'''
from sklearn.model_selection import train_test_split
X = [[1], [2], [3], [4], [5], [6]]
y = [0, 0, 1, 1, 1, 0]
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.33, random_state=7)
print(len(Xtr), len(Xte))
''',
              expected: '4 2',
            ),
            mistakes: const [
              'Scaling the full dataset before splitting.',
              'Random splits on time-series data.',
            ],
            quiz: [
              mcq(
                id: 'q_ds_01',
                question: 'When should a StandardScaler be fit?',
                options: [
                  opt('1', 'On the training fold only', true),
                  opt('2', 'On train+test together', false),
                  opt('3', 'After the model is trained', false),
                ],
                explanation: 'Test statistics must stay unseen.',
                topic: 'Data Science',
              ),
            ],
            takeaways: const ['Three splits, three jobs.', 'Fit transforms on train only.'],
            tech: const ['tech_sklearn'],
          ),
          lesson(
            id: 'ds_02',
            trackId: id,
            moduleId: mod,
            title: 'Feature Engineering that Models Can Use',
            subtitle: 'Missing values, encoding, and scale',
            minutes: 8,
            xp: 50,
            concept:
                'Models see numbers. Encoding, imputation, and scaling decide whether those numbers mean anything.',
            why: 'Tree models tolerate raw scale; linear models and networks do not.',
            eli5: 'You can’t add apples to kilometers. Convert first.',
            engineer:
                'Prefer target-aware encodings with CV. Median impute skewed numerics; add a missingness indicator when absence is a signal.',
            analogy: 'Translating every ingredient into grams before baking.',
            takeaways: const ['Scale for linear/NN models.', 'Missingness can be a feature.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _machineLearning() {
  const id = 'track_ml';
  const mod = 'mod_ml_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 3,
    title: 'Machine Learning',
    tagline: 'Supervised, unsupervised, metrics, and regularization',
    icon: '🤖',
    colorHex: '#43A047',
    description:
        'Linear models, trees, boosting, clustering, PCA, and the metrics that keep you honest — explained simply, with practical scikit-learn examples.',
    keySkills: const ['Scikit-learn', 'Ensembles', 'Regularization', 'Metrics', 'Cross-validation'],
    prerequisiteTrackIds: const ['track_ds'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Classical ML that still ships',
        description: 'Baselines you should beat before reaching for a transformer.',
        lessons: [
          lesson(
            id: 'ml_01',
            trackId: id,
            moduleId: mod,
            title: 'Bias, Variance & Regularization',
            subtitle: 'Why models overfit and how you pull them back',
            minutes: 10,
            xp: 60,
            concept:
                'Bias is systematic error from a hypothesis class that is too simple. Variance is sensitivity to the sample. Regularization trades a little bias for a lot less variance.',
            why: 'Most “the model is bad” reports are unregularized memorization.',
            eli5:
                'A student who memorizes last year’s exam (high variance) vs. one who only learned “always pick C” (high bias).',
            engineer:
                'L2 shrinks weights; dropout samples subnetworks; early stopping is implicit regularization. Watch the train/val gap.',
            analogy: 'A tailored suit versus a circus tent — both fail for different reasons.',
            formula: 'L(θ) = L_data(θ) + λ Ω(θ)',
            quiz: [
              mcq(
                id: 'q_ml_01',
                question: 'A huge train/val gap usually indicates',
                options: [
                  opt('1', 'Overfitting (high variance)', true),
                  opt('2', 'Perfect calibration', false),
                  opt('3', 'Data leakage to the opposite direction', false),
                ],
                explanation: 'Memorization lifts train metrics while val stays honest.',
                topic: 'ML concepts',
              ),
            ],
            takeaways: const ['Watch the gap, not only the score.', 'λ is a knob, not a moral value.'],
          ),
          lesson(
            id: 'ml_02',
            trackId: id,
            moduleId: mod,
            title: 'Classification Metrics that Survive Production',
            subtitle: 'Accuracy is a vanity metric on imbalanced data',
            minutes: 8,
            xp: 55,
            concept:
                'Precision, recall, F1, ROC-AUC, and PR-AUC answer different questions. Pick the one that matches the cost of errors.',
            why: 'A 99% accurate fraud model that never flags fraud is useless.',
            eli5: 'Catching every apple (recall) versus only grabbing real apples (precision).',
            engineer:
                'For rare positives, PR-AUC > ROC-AUC. Thresholds belong to the product, not the notebook.',
            analogy: 'Airport security (high recall) versus a spam folder (precision-sensitive).',
            takeaways: const ['Choose metrics from costs.', 'Thresholds are product decisions.'],
            projects: const ['proj_01'],
          ),
          lesson(
            id: 'ml_03',
            trackId: id,
            moduleId: mod,
            title: 'Trees, Forests & Gradient Boosting',
            subtitle: 'The default tabular stack',
            minutes: 9,
            xp: 60,
            concept:
                'Decision trees partition the space. Forests average uncorrelated trees. Boosting fits residual errors sequentially (XGBoost, LightGBM, CatBoost).',
            why: 'On tabular business data, boosted trees still beat most deep models.',
            eli5: 'Many slightly different judges vote (forest). Or each judge studies the previous judge’s mistakes (boosting).',
            engineer:
                'Watch for target leakage in features. Use early stopping on a validation set. Monotonic constraints encode domain rules.',
            analogy: 'A panel of specialists versus one intern with a flowchart.',
            takeaways: const ['Trees are strong tabular baselines.', 'Boosting fits residuals.'],
            tech: const ['tech_sklearn'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _deepLearning() {
  const id = 'track_dl';
  const mod = 'mod_dl_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 4,
    title: 'Deep Learning',
    tagline: 'Neural nets from scratch to CNNs, RNNs, and GANs',
    icon: '🧠',
    colorHex: '#9C27B0',
    description:
        'Neural networks explained simply, from a single neuron up: backprop, regularization, CNNs for images, RNNs/LSTMs for sequences, and generative models like autoencoders and GANs.',
    keySkills: const ['Backpropagation', 'Regularization', 'CNNs', 'RNNs/LSTM', 'Transfer learning'],
    prerequisiteTrackIds: const ['track_ml'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Neural networks from scratch',
        description: 'Forward, backward, and why nonlinearity matters.',
        lessons: [
          lesson(
            id: 'dl_01',
            trackId: id,
            moduleId: mod,
            title: 'Understanding Neural Networks',
            subtitle: 'Stacked linear maps plus nonlinearity become universal approximators',
            minutes: 12,
            xp: 75,
            concept:
                'A multi-layer perceptron stacks affine maps z = Wx + b and a nonlinearity a = σ(z). Without σ, stacked layers collapse into one matrix multiply.',
            why:
                'Non-linear activations let networks approximate speech, vision, language, and tools — they are the reason depth works.',
            eli5:
                'Each station on a factory line inspects the part and applies a filter. By the end, raw metal looks like a finished tool.',
            engineer:
                'Backprop applies the chain rule in reverse topological order. Autograd stores Jacobian-vector products so you never write derivatives by hand.',
            analogy: 'First layer sees edges, next sees ears, last says “cat”.',
            formula: 'a^[l] = ReLU(W^[l] a^[l-1] + b^[l])',
            mathIntuition: 'ReLU keeps gradient = 1 for z>0, avoiding the vanishing of saturating sigmoids.',
            visualizer: VisualizerType.neuralNetwork,
            code: py(
              'PyTorch MLP',
              r'''
import torch
import torch.nn as nn

class MLP(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 10),
        )
    def forward(self, x):
        return self.net(x)

logits = MLP()(torch.randn(32, 128))
print(tuple(logits.shape))
''',
              explanation: 'Batch of 32, 10 logits.',
              expected: '(32, 10)',
            ),
            mistakes: const [
              'Forgetting activations between linear layers.',
              'Sigmoid in deep hidden layers.',
              'Shape mismatches on the last Linear.',
            ],
            interview: interview(
              question: 'Why do we need non-linear activations?',
              answer:
                  'Linear layers compose into one linear map. Non-linearities create non-linear decision boundaries and enable universal approximation.',
              followUps: const ['What is dying ReLU, and how do GELU/LeakyReLU help?'],
              terms: const ['ReLU', 'Chain rule', 'Logits'],
              topic: 'Deep Learning',
            ),
            quiz: [
              mcq(
                id: 'q_dl_01',
                question: 'ReLU(−4.5) equals',
                options: [
                  opt('1', '0.0', true),
                  opt('2', '−4.5', false),
                  opt('3', '1.0', false),
                ],
                explanation: 'ReLU(z) = max(0, z).',
                topic: 'Deep Learning',
                type: QuizQuestionType.math,
              ),
            ],
            takeaways: const [
              'Depth needs nonlinearity.',
              'Backprop is the chain rule on a graph.',
              'Autograd records the tape; you define the forward.',
            ],
            tech: const ['tech_pytorch'],
          ),
          lesson(
            id: 'dl_02',
            trackId: id,
            moduleId: mod,
            title: 'CNNs, Receptive Fields & Transfer Learning',
            subtitle: 'Weight sharing that understands space',
            minutes: 10,
            xp: 70,
            concept:
                'Convolutions apply the same small filter across space. Stacking them grows receptive field. Transfer learning reuses filters trained on ImageNet.',
            why: 'From medical imaging to OCR, conv nets (and later ViTs) are the perception backbone.',
            eli5: 'A stamp you press over every part of a photo, looking for the same pattern.',
            engineer:
                'Fine-tune last blocks first. Augment geometrically. Watch for resolution mismatch between pretraining and your domain.',
            analogy: 'A jeweler’s loupe sliding across a canvas.',
            visualizer: VisualizerType.neuralNetwork,
            takeaways: const ['Shared weights = parameter efficiency.', 'Fine-tune, don’t always train from scratch.'],
            tech: const ['tech_pytorch'],
            projects: const ['proj_01'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _computerVision() {
  const id = 'track_cv';
  const mod = 'mod_cv_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 5,
    title: 'Computer Vision',
    tagline: 'Pixels, detection, segmentation, and modern backbones',
    icon: '📷',
    colorHex: '#5C6BC0',
    description:
        'Image fundamentals explained simply, from pixels to CNN backbones, object detection with YOLO, segmentation, evaluation, and a preview of Vision Transformers and multimodal models.',
    keySkills: const ['OpenCV', 'CNNs/ResNet', 'YOLO', 'Segmentation', 'ViT'],
    prerequisiteTrackIds: const ['track_dl'],
    careerGoals: const [CareerGoal.cvEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Seeing with models',
        description: 'From pixels to boxes and masks.',
        lessons: [
          lesson(
            id: 'cv_01',
            trackId: id,
            moduleId: mod,
            title: 'Pixels, Channels & Preprocessing',
            subtitle: 'What a tensor actually contains',
            minutes: 8,
            xp: 50,
            concept:
                'An image is a H×W×C tensor. Models expect a consistent color space, range, and size. Augmentation is training-time distribution widening.',
            why: 'Most “the detector is dumb” bugs are resize/normalize mismatches.',
            eli5: 'A photo is a grid of colored dots. The model only understands a very specific grid.',
            engineer:
                'Match mean/std to the pretrained checkpoint. Keep aspect ratio with letterbox for detectors.',
            analogy: 'Framing a painting so it fits a museum wall without stretching faces.',
            takeaways: const ['Normalize like the checkpoint.', 'Augment train, not test (usually).'],
          ),
          lesson(
            id: 'cv_02',
            trackId: id,
            moduleId: mod,
            title: 'Detection vs Segmentation vs Classification',
            subtitle: 'Pick the output head that matches the job',
            minutes: 8,
            xp: 55,
            concept:
                'Classification names the image. Detection draws boxes. Segmentation labels pixels. Each has different loss geometry and data cost.',
            why: 'Building a detector when a classifier suffices wastes months of labeling.',
            eli5: '“This is a cat” vs “the cat is here” vs “these exact fur pixels”.',
            engineer:
                'Start with classification if the object dominates the frame. Use YOLO/RT-DETR when multiple instances matter.',
            analogy: 'A museum caption, a sticky note on the frame, or tracing every brush stroke.',
            takeaways: const ['Task choice dominates architecture choice.', 'Label cost scales with spatial precision.'],
          ),
        ],
      ),
    ],
  );
}
