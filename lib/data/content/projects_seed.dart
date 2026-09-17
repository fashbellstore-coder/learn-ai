import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import 'lesson_factory.dart';
import 'specialist_projects.dart';

class ProjectsSeed {
  const ProjectsSeed();

  List<Project> all() => [
        ...specialistProjects(),
        Project(
          id: 'proj_01',
          title: 'Spam & Phishing Classifier',
          subtitle: 'TF-IDF, logistic regression, and a calibrated decision threshold',
          tier: ProjectTier.beginner,
          category: 'Machine Learning',
          estimatedHours: '3 hours',
          xpReward: 150,
          icon: 'SP',
          objective:
              'Ship a text classifier with precision/recall you would actually trust in an inbox.',
          architectureOverview:
              'Raw text → cleaning → TF-IDF → logistic regression → threshold → FastAPI.',
          architectureDiagram: '''
[Email / SMS]
      │
      ▼
[Normalize + n-grams]
      │
      ▼
[TF-IDF 5k features]
      │
      ▼
[LogReg + calibration]
      │
 ├── spam (p > 0.85)
 └── ham
''',
          techStack: const ['Python', 'Scikit-learn', 'NLTK', 'FastAPI'],
          requirements: const [
            'Clean a labeled SMS/email set',
            'Fit a Pipeline with TF-IDF + LogReg',
            'Report F1 and ROC-AUC',
            'Export joblib for inference',
          ],
          conceptsUsed: const ['TF-IDF', 'Confusion matrix', 'Precision-recall'],
          steps: [
            ProjectStep(
              stepNumber: 1,
              title: 'Normalize without destroying signal',
              explanation: 'Lowercase, redact URLs, keep enough tokens for n-grams.',
              codeSnippet: py(
                'Cleaner',
                r'''
import re
def clean(text: str) -> str:
    text = text.lower()
    text = re.sub(r'http\S+', '[URL]', text)
    return text.strip()
print(clean("WIN $1000 at http://x.com"))
''',
              ),
            ),
            ProjectStep(
              stepNumber: 2,
              title: 'Assemble the pipeline',
              explanation: 'Vectorizer and classifier must ship as one artifact.',
              codeSnippet: py(
                'Pipeline',
                r'''
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
pipe = Pipeline([
  ('tfidf', TfidfVectorizer(max_features=5000, ngram_range=(1,2))),
  ('clf', LogisticRegression(max_iter=200)),
])
print(list(pipe.named_steps))
''',
              ),
            ),
          ],
          fullSourceCode: r'''
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression

X = [
  "urgent account suspended click",
  "lunch at 1pm?",
  "you won a free vacation",
  "quarterly report attached",
]
y = [1, 0, 1, 0]
pipe = Pipeline([
  ('tfidf', TfidfVectorizer(ngram_range=(1, 2))),
  ('clf', LogisticRegression()),
])
pipe.fit(X, y)
print(pipe.predict(["free lottery click here"])[0])
''',
          testingStrategy: 'Stratified CV. Optimize F1 at a high-precision operating point.',
          deploymentGuide: 'Wrap the joblib artifact in FastAPI. Pin sklearn versions.',
          challengesAndImprovements: const [
            'Character n-grams for obfuscation.',
            'Distilled transformer head for semantic phishing.',
          ],
        ),
        Project(
          id: 'proj_02',
          title: 'PDF Knowledge Assistant',
          subtitle: 'Hybrid RAG with citations you can click',
          tier: ProjectTier.intermediate,
          category: 'Generative AI & RAG',
          estimatedHours: '6 hours',
          xpReward: 300,
          icon: 'PD',
          objective: 'Ingest PDFs, retrieve hybrid context, answer with page citations.',
          architectureOverview:
              'Parse → chunk → dense+BM25 → Qdrant → RRF → rerank → grounded generate.',
          architectureDiagram: '''
[PDF]
  ▼
[Layout-aware chunks]
  ▼
[Dense + BM25]
  ▼
[Qdrant hybrid]
  ▼
[Rerank]
  ▼
[LLM + citations]
''',
          techStack: const ['Python', 'Qdrant', 'PyMuPDF', 'FastAPI'],
          requirements: const [
            'Preserve headings and page numbers',
            '512-token windows, 64 overlap',
            'Hybrid retrieval + citations',
          ],
          conceptsUsed: const ['HNSW', 'Cosine', 'RRF', 'Grounding'],
          steps: [
            ProjectStep(
              stepNumber: 1,
              title: 'Chunk with metadata',
              explanation: 'Never lose page_number. It is your citation.',
              codeSnippet: py(
                'Chunker',
                r'''
def chunk(words, size=80, overlap=16):
    out = []
    step = max(1, size - overlap)
    for i in range(0, len(words), step):
        out.append(" ".join(words[i:i+size]))
    return out
print(len(chunk("alpha beta gamma delta".split(), size=2, overlap=1)))
''',
              ),
            ),
          ],
          fullSourceCode: r'''
class MiniRAG:
    def __init__(self):
        self.docs = []
    def add(self, title, page, text):
        self.docs.append((title, page, text))
    def search(self, q):
        return [d for d in self.docs if q.lower()[:3] in d[2].lower()][:2]

r = MiniRAG()
r.add("Whitepaper", 1, "RAG grounds LLMs with retrieved context.")
print(len(r.search("ground")))
''',
          testingStrategy: 'Ragas faithfulness > 0.9 and context recall > 0.85 on a gold set.',
          deploymentGuide: 'Qdrant + API behind TLS. Store hashes of source PDFs.',
          challengesAndImprovements: const [
            'Parent-child retrieval.',
            'Vision parse for figures.',
          ],
        ),
        Project(
          id: 'proj_03',
          title: 'Multi-Agent Research Swarm',
          subtitle: 'Planner, researcher, critic, editor on a state graph',
          tier: ProjectTier.advanced,
          category: 'Agentic AI',
          estimatedHours: '8 hours',
          xpReward: 500,
          icon: 'SW',
          objective: 'A supervisor delegates research and refuses to publish uncited claims.',
          architectureOverview: 'Supervisor → specialists → critic loop → memo.',
          architectureDiagram: '''
[Goal]
   ▼
[Planner]
   ├── [Web]
   └── [Analyst]
          ▼
       [Critic] -- revise --> [Planner]
          │
          approve
          ▼
       [Editor]
''',
          techStack: const ['Python', 'LangGraph', 'Pydantic', 'FastAPI'],
          requirements: const [
            'Typed state',
            'Human gate before publish',
            'Max-step guard',
          ],
          conceptsUsed: const ['StateGraph', 'HITL', 'Tool calling'],
          steps: [
            ProjectStep(
              stepNumber: 1,
              title: 'Define reducers',
              explanation: 'Messages append. Status overwrites.',
              codeSnippet: py(
                'State',
                r'''
from typing import TypedDict, List
class SwarmState(TypedDict):
    topic: str
    notes: List[str]
    memo: str
print(SwarmState.__annotations__["topic"])
''',
              ),
            ),
          ],
          fullSourceCode: r'''
state = {"topic": "Agentic AI", "notes": [], "memo": ""}
state["notes"].append("Market growing quickly.")
state["memo"] = f"# {state['topic']}\n- {state['notes'][0]}"
print(state["memo"].splitlines()[0])
''',
          testingStrategy: 'Mock tools. Assert the critic can force another loop.',
          deploymentGuide: 'Redis checkpointer. Stream tokens over WebSockets.',
          challengesAndImprovements: const ['Long-term memory.', 'Live debate UI.'],
        ),
        Project(
          id: 'proj_04',
          title: 'Enterprise MCP Server',
          subtitle: 'Safe SQL, schema resources, troubleshooting prompts',
          tier: ProjectTier.expert,
          category: 'Model Context Protocol',
          estimatedHours: '10 hours',
          xpReward: 750,
          icon: 'MC',
          objective: 'Expose Postgres metadata and read-only queries to any MCP host.',
          architectureOverview: 'Host ↔ JSON-RPC ↔ FastMCP ↔ SQLAlchemy.',
          architectureDiagram: r'''
[Cursor / Claude / custom host]
            | JSON-RPC
            v
      [FastMCP server]
     /       |        \
  tools   resources   prompts
     \       |        /
          [Postgres]
''',
          techStack: const ['Python 3.12', 'FastMCP', 'SQLAlchemy', 'Pydantic'],
          requirements: const [
            'SELECT/EXPLAIN only',
            'Schema as resources',
            'stdio + HTTP transports',
          ],
          conceptsUsed: const ['MCP', 'JSON-RPC', 'Least privilege'],
          steps: [
            ProjectStep(
              stepNumber: 1,
              title: 'Register a typed tool',
              explanation: 'Docstrings become the model-facing API.',
              codeSnippet: py(
                'Tool',
                r'''
def describe_table(name: str) -> str:
    """Return columns for a table."""
    return f"{name}: id uuid, created_at timestamptz"
print(describe_table("users")[:5])
''',
              ),
            ),
          ],
          fullSourceCode: r'''
def execute_safe_sql(query: str) -> str:
    q = query.strip().lower()
    if not (q.startswith("select") or q.startswith("explain")):
        raise ValueError("read-only")
    return '[{"active_users": 1420}]'
print(execute_safe_sql("SELECT 1"))
''',
          testingStrategy: 'MCP Inspector for schema + error codes. Reject writes.',
          deploymentGuide: 'Containerize. Scope OAuth for remote transports.',
          challengesAndImprovements: const ['Streaming tools.', 'Row-level security passthrough.'],
        ),
        Project(
          id: 'proj_05',
          title: 'Local LLM Workbench',
          subtitle: 'llama.cpp or vLLM, streaming, and prompt evals',
          tier: ProjectTier.advanced,
          category: 'LLM Engineering',
          estimatedHours: '7 hours',
          xpReward: 420,
          icon: 'LV',
          objective: 'Run a local model with a prompt suite and latency dashboard.',
          architectureOverview: 'Client → OpenAI-compatible server → local engine.',
          architectureDiagram: '''
[App]
  ▼
[OpenAI API shim]
  ▼
[vLLM / llama.cpp]
  ▼
[Eval suite]
''',
          techStack: const ['Python', 'vLLM', 'FastAPI'],
          requirements: const ['Streaming tokens', 'Gold-set eval', 'Cost/latency log'],
          conceptsUsed: const ['KV cache', 'Quantization', 'Evals'],
          steps: const [
            ProjectStep(
              stepNumber: 1,
              title: 'Pin a small instruct model',
              explanation: 'Start tiny. Measure tokens/sec before UX polish.',
            ),
          ],
          fullSourceCode: 'print("local-llm-workbench")',
          testingStrategy: 'Regression eval on 30 prompts each PR.',
          deploymentGuide: 'GPU node or Apple Silicon. Never embed vendor keys in the mobile app.',
          challengesAndImprovements: const ['Speculative decoding.', 'Structured output grammar.'],
        ),
        Project(
          id: 'proj_06',
          title: 'Image Classifier with Transfer Learning',
          subtitle: 'Fine-tune a ResNet on a small custom dataset',
          tier: ProjectTier.beginner,
          category: 'Computer Vision',
          estimatedHours: '4 hours',
          xpReward: 180,
          icon: 'IM',
          objective: 'Beat a from-scratch CNN using a frozen backbone and a new linear head.',
          architectureOverview: 'Images → augment → pretrained ResNet → linear head → eval.',
          architectureDiagram: '''
[Photos]
   ▼
[Augment]
   ▼
[ResNet backbone]
   ▼
[Linear head]
   ▼
[Metrics]
''',
          techStack: const ['Python', 'PyTorch', 'torchvision'],
          requirements: const ['Train/val split by folder', 'Freeze then unfreeze last block', 'Report accuracy + confusion'],
          conceptsUsed: const ['Transfer learning', 'Augmentation', 'Overfitting'],
          steps: [
            ProjectStep(
              stepNumber: 1,
              title: 'Freeze the backbone',
              explanation: 'Train the head first so you do not wreck ImageNet features.',
              codeSnippet: py(
                'Freeze',
                r'''
def freeze(model):
    for p in model.parameters():
        p.requires_grad = False
    print("frozen")
freeze(type("M", (), {"parameters": lambda self: []})())
''',
              ),
            ),
          ],
          fullSourceCode: 'print("transfer-learning-baseline")',
          testingStrategy: 'Hold out a site or camera so you do not leak lighting.',
          deploymentGuide: 'Export TorchScript or ONNX. Do not ship training augmentations.',
          challengesAndImprovements: const ['Class imbalance sampler.', 'Test-time augmentation.'],
        ),
        Project(
          id: 'proj_07',
          title: 'Semantic Search over Notes',
          subtitle: 'Embed, index, and retrieve personal notes with citations',
          tier: ProjectTier.intermediate,
          category: 'Embeddings',
          estimatedHours: '5 hours',
          xpReward: 260,
          icon: 'NT',
          objective: 'A notes app that answers with the note title and quote, not a vibe.',
          architectureOverview: 'Notes → chunk → embed → Qdrant → cite.',
          architectureDiagram: '''
[Note]
  ▼
[Chunk]
  ▼
[Embed]
  ▼
[Index]
  ▼
[Cited answer]
''',
          techStack: const ['Python', 'Qdrant', 'Sentence Transformers'],
          requirements: const ['Same model at index and query', 'Return note id + span', 'Hybrid fallback'],
          conceptsUsed: const ['Cosine', 'Chunking', 'Citations'],
          steps: const [
            ProjectStep(
              stepNumber: 1,
              title: 'Normalize then embed',
              explanation: 'L2-normalize if you use cosine/dot interchangeably.',
            ),
          ],
          fullSourceCode: 'print("notes-search")',
          testingStrategy: 'Ten questions with known note ids. Measure recall@5.',
          deploymentGuide: 'Local-first index. Encrypt at rest if notes are personal.',
          challengesAndImprovements: const ['Incremental reindex.', 'Multilingual model.'],
        ),
        Project(
          id: 'proj_08',
          title: 'Production RAG Eval Harness',
          subtitle: 'Faithfulness, context recall, and a nightly CI gate',
          tier: ProjectTier.expert,
          category: 'Evaluation',
          estimatedHours: '9 hours',
          xpReward: 640,
          icon: 'EV',
          objective: 'A gold set that can fail a deploy when a prompt “improvement” regresses.',
          architectureOverview: 'Gold Q/A → retrieve → generate → metric → gate.',
          architectureDiagram: '''
[Gold set]
    ▼
[Retrieve + generate]
    ▼
[Faithfulness / recall]
    ▼
[CI gate]
''',
          techStack: const ['Python', 'Ragas', 'pytest', 'Langfuse'],
          requirements: const ['Frozen gold set', 'Fail on −3% faithfulness', 'Trace every run'],
          conceptsUsed: const ['Faithfulness', 'CI', 'Lineage'],
          steps: const [
            ProjectStep(
              stepNumber: 1,
              title: 'Freeze the questions',
              explanation: 'If the gold set moves weekly, you cannot see regressions.',
            ),
          ],
          fullSourceCode: 'print("rag-eval-harness")',
          testingStrategy: 'Deterministic retriever mock + flaky-metric budget.',
          deploymentGuide: 'Run in CI on prompt/chunker PRs. Store traces.',
          challengesAndImprovements: const ['LLM-as-judge calibration.', 'Human spot checks.'],
        ),
      ];
}
