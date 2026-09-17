import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import 'lesson_factory.dart';

List<RoadmapTrack> advancedTracks() => [
      _nlp(),
      _transformers(),
      _huggingface(),
      _genai(),
      _llm(),
      _embeddings(),
      _rag(),
      _finetune(),
      _agents(),
      _langgraph(),
      _mcp(),
      _mlops(),
      _llmops(),
      _evalSecurity(),
    ];

RoadmapTrack _nlp() {
  const id = 'track_nlp';
  const mod = 'mod_nlp_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 6,
    title: 'Natural Language Processing',
    tagline: 'Tokenization to embeddings, attention, and modern NLP',
    icon: '💬',
    colorHex: '#00897B',
    description: 'Classic NLP explained simply — tokenization, TF-IDF, word embeddings, attention, and core tasks like sentiment analysis, NER, summarization, and QA — before the jump to contextual models.',
    keySkills: const ['Tokenization', 'TF-IDF', 'Embeddings', 'Attention', 'NER'],
    prerequisiteTrackIds: const ['track_ml'],
    careerGoals: const [CareerGoal.nlpEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Text as data',
        description: 'Preprocess, represent, classify.',
        lessons: [
          lesson(
            id: 'nlp_01',
            trackId: id,
            moduleId: mod,
            title: 'Tokenization, Stems & When to Stop Cleaning',
            subtitle: 'Every normalize step can destroy signal',
            minutes: 8,
            xp: 50,
            concept:
                'Tokenization splits text into model-facing units. Stemming/lemmatization collapse variants. Over-cleaning removes the very cues a classifier needs (negation, domain jargon).',
            why: 'A spam filter that strips digits will miss “wire 10000 now”.',
            eli5: 'Cutting a sentence into LEGO bricks before you rebuild meaning.',
            engineer:
                'For classical models, prefer lemmatization + n-grams. For transformers, use the model’s own tokenizer — never a custom splitter.',
            analogy: 'Translating a poem after deleting all the punctuation.',
            takeaways: const ['Use the model’s tokenizer.', 'Cleaning is a product decision.'],
          ),
          lesson(
            id: 'nlp_02',
            trackId: id,
            moduleId: mod,
            title: 'TF-IDF and the Limits of Bags of Words',
            subtitle: 'Counts that still win on short, labeled text',
            minutes: 8,
            xp: 50,
            concept:
                'TF-IDF weights terms that are frequent in a document but rare in the corpus. It cannot model order or negation well.',
            why: 'Still the correct first baseline for tickets, reviews, and spam.',
            eli5: 'Words that appear in this email but almost nowhere else get a gold star.',
            engineer: 'Add character n-grams for obfuscation. Calibrate thresholds on a held-out week.',
            analogy: 'Highlighting rare stamps in a collection, ignoring “the” and “and”.',
            projects: const ['proj_01'],
            takeaways: const ['Always ship a TF-IDF baseline.', 'Order needs sequence models.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _transformers() {
  const id = 'track_transformers';
  const mod = 'mod_trans_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 7,
    title: 'Transformers',
    tagline: 'Attention, QKV, multi-head, positional encoding',
    icon: '🔍',
    colorHex: '#00BCD4',
    description:
        'The architecture behind modern LLMs: scaled dot-product attention, multi-head, residuals, and RoPE.',
    keySkills: const ['Self-attention', 'QKV', 'Multi-head', 'RoPE', 'BERT/GPT'],
    prerequisiteTrackIds: const ['track_dl'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Attention is all you need',
        description: 'From scores to contextual embeddings.',
        lessons: [
          lesson(
            id: 'trans_01',
            trackId: id,
            moduleId: mod,
            title: 'Scaled Dot-Product Attention & QKV',
            subtitle: 'How queries, keys, and values build context',
            minutes: 15,
            xp: 100,
            concept:
                'Each token is projected into Query (what I seek), Key (what I offer as a label), and Value (the content I pass on). Attention(Q,K,V) = softmax(QKᵀ / √d_k) V.',
            why:
                'Attention replaced sequential RNNs, enabling full-sequence GPU parallelism and the scale of foundation models.',
            eli5:
                'You ask the library a question (Q), scan spine labels (K), and pull the matching paragraphs (V).',
            engineer:
                '√d_k keeps softmax out of saturated tails. Multi-head splits d_model so heads can specialize (syntax vs entities vs long-range).',
            analogy: 'In “the bank of the river”, bank attends to river, not finance.',
            formula: 'Attention(Q,K,V) = softmax(QKᵀ / √d_k) V',
            mathIntuition: 'Dot = alignment. Softmax = distribution. Times V = weighted mix of values.',
            visualizer: VisualizerType.attentionHeatmap,
            code: py(
              'Attention in PyTorch',
              r'''
import torch
import torch.nn.functional as F

Q = torch.randn(1, 4, 64)
K = torch.randn(1, 4, 64)
V = torch.randn(1, 4, 64)
scores = Q @ K.transpose(-2, -1) / (64 ** 0.5)
weights = F.softmax(scores, dim=-1)
ctx = weights @ V
print(tuple(weights.shape), tuple(ctx.shape))
''',
              expected: '(1, 4, 4) (1, 4, 64)',
            ),
            mistakes: const [
              'Forgetting √d_k.',
              'Missing causal masks in decoders.',
              'Incorrect head split of the projection.',
            ],
            interview: interview(
              question: 'Complexity of standard self-attention in N and D?',
              answer:
                  'O(N² D) from the N×N score matrix. Long context needs IO-aware kernels (FlashAttention) or sparse/linear variants.',
              followUps: const ['How does GQA shrink the KV cache?'],
              terms: const ['QKV', 'FlashAttention', 'KV cache'],
              topic: 'Transformers',
            ),
            quiz: [
              mcq(
                id: 'q_trans_01',
                question: 'Why scale QKᵀ by √d_k?',
                options: [
                  opt('1', 'Keep softmax in a healthy gradient region', true),
                  opt('2', 'Reduce the number of heads', false),
                  opt('3', 'Make the matrix symmetric', false),
                ],
                explanation: 'Variance of the dot grows with d_k; scaling restores unit scale.',
                topic: 'Transformers',
              ),
            ],
            takeaways: const [
              'Attention is input-dependent mixing.',
              'Q, K, V play different roles.',
              'Transformers train in parallel over the sequence.',
            ],
            tech: const ['tech_pytorch', 'tech_huggingface'],
          ),
          lesson(
            id: 'trans_02',
            trackId: id,
            moduleId: mod,
            title: 'Encoder, Decoder & Causal Masks',
            subtitle: 'BERT reads; GPT writes',
            minutes: 10,
            xp: 70,
            concept:
                'Encoders see the full sequence (bidirectional). Decoders mask the future so generation is causal. Encoder-decoder (T5) conditions generation on a separate read stream.',
            why: 'Choosing the wrong mask is the difference between a classifier and a chatbot.',
            eli5: 'Reading a whole page vs writing the next word without peeking ahead.',
            engineer:
                'Training uses teacher forcing with a causal mask. Inference is autoregressive and KV-cached.',
            analogy: 'Closed-book exam (decoder) vs open-book (encoder).',
            takeaways: const ['Mask defines the task.', 'KV cache makes decoding affordable.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _huggingface() {
  const id = 'track_hf';
  const mod = 'mod_hf_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 8,
    title: 'Hugging Face Ecosystem',
    tagline: 'Hub, Transformers, Datasets, PEFT, Accelerate',
    icon: '🤗',
    colorHex: '#FFD21E',
    description: 'Load, tokenize, fine-tune, evaluate, and publish models without reinventing plumbing.',
    keySkills: const ['Transformers', 'Tokenizers', 'PEFT', 'Datasets', 'Safetensors'],
    prerequisiteTrackIds: const ['track_transformers'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'The Hub as infrastructure',
        description: 'One API across architectures.',
        lessons: [
          lesson(
            id: 'hf_01',
            trackId: id,
            moduleId: mod,
            title: 'Load, Tokenize, Infer',
            subtitle: 'The three calls you will write a thousand times',
            minutes: 8,
            xp: 55,
            concept:
                'AutoTokenizer + AutoModel give a consistent surface over BERT, Llama, Gemma, and Qwen. Pipelines hide the boilerplate for common tasks.',
            why: 'Most “I trained a model” work starts as Hub reuse, not a paper reimplementation.',
            eli5: 'A library card that works for every book in the building.',
            engineer:
                'Pin revisions. Prefer safetensors. Move to vLLM when you need concurrency, not when you need a demo.',
            analogy: 'USB-C for checkpoints.',
            tech: const ['tech_huggingface'],
            takeaways: const ['Pin model revisions.', 'Pipelines for prototypes, trainers for research.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _genai() {
  const id = 'track_genai';
  const mod = 'mod_gen_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 9,
    title: 'Generative AI',
    tagline: 'LLMs, diffusion, multimodal generation',
    icon: '🎨',
    colorHex: '#EC407A',
    description: 'What generative models are, where they fail, and how text/image/audio systems differ.',
    keySkills: const ['LLMs', 'Diffusion', 'Multimodal', 'Sampling'],
    prerequisiteTrackIds: const ['track_transformers'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Generating, not classifying',
        description: 'From likelihood to pixels and tokens.',
        lessons: [
          lesson(
            id: 'gen_01',
            trackId: id,
            moduleId: mod,
            title: 'What Generative AI Actually Is',
            subtitle: 'Learning p(x) instead of p(y|x)',
            minutes: 8,
            xp: 50,
            concept:
                'Discriminative models predict labels. Generative models learn enough structure to sample new x — tokens, pixels, spectrograms.',
            why: 'Product teams confuse “chat UI” with “generative model”. The distinction drives eval and safety.',
            eli5: 'A student who can only pick A/B/C vs a student who can write a new story.',
            engineer:
                'Autoregressive LMs factor p(x) = Π p(x_t | x_<t). Diffusion learns to reverse noise. Different likelihoods, different failure modes.',
            analogy: 'A portrait painter versus a museum security guard naming the artist.',
            takeaways: const ['Generation is density modeling.', 'Sampling knobs change style and risk.'],
          ),
          lesson(
            id: 'gen_02',
            trackId: id,
            moduleId: mod,
            title: 'Temperature, Top-p & Structured Output',
            subtitle: 'Sampling is a product surface',
            minutes: 8,
            xp: 55,
            concept:
                'Temperature sharpens or flattens the next-token distribution. Top-p keeps a nucleus of mass. Structured output constrains tokens to a schema.',
            why: 'A support bot and a brainstorming partner should not share the same sampler.',
            eli5: 'A careful student vs a jazz musician — same knowledge, different daring.',
            engineer:
                'For tools/JSON, use constrained decoding, not “please return JSON”. Logit bias is a blunt instrument.',
            analogy: 'A chef following a recipe versus improvising with leftovers.',
            takeaways: const ['Low T for tools.', 'Constrain the grammar, don’t plead.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _llm() {
  const id = 'track_llm';
  const mod = 'mod_llm_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 10,
    title: 'LLM Engineering',
    tagline: 'Prompts, tools, context windows, local and API models',
    icon: '⚙️',
    colorHex: '#7E57C2',
    description: 'The working engineer’s surface: system prompts, tools, streaming, and evaluation.',
    keySkills: const ['Prompting', 'Tool calling', 'Streaming', 'Context', 'Evals'],
    prerequisiteTrackIds: const ['track_genai'],
    careerGoals: const [CareerGoal.llmEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'From prompt to production call',
        description: 'Contracts, not vibes.',
        lessons: [
          lesson(
            id: 'llm_01',
            trackId: id,
            moduleId: mod,
            title: 'System Prompts, Tools & Structured Contracts',
            subtitle: 'Treat the model like an untrusted coworker with an API',
            minutes: 10,
            xp: 70,
            concept:
                'System prompts set policy. Tools expose typed side effects. Structured output is a schema, not a suggestion.',
            why: 'Most production incidents are unbounded generation plus unbounded tools.',
            eli5: 'A job description, a toolbox, and a form the worker must fill.',
            engineer:
                'Keep policy in the system prompt, facts in retrieved context, and actions in tools with allow-lists. Log traces.',
            analogy: 'A kitchen with a menu, a knife drawer, and a ticket printer.',
            takeaways: const ['Separate policy, context, and tools.', 'Schema-first outputs.'],
          ),
          lesson(
            id: 'llm_02',
            trackId: id,
            moduleId: mod,
            title: 'Context Windows, Tokens & Cost',
            subtitle: 'Every token is latency, money, and attention',
            minutes: 8,
            xp: 55,
            concept:
                'Tokenizers define the true length. Long context degrades (“lost in the middle”) and explodes KV cache.',
            why: 'Dumping a 200-page PDF into the prompt is not an architecture.',
            eli5: 'A backpack that gets heavier and messier the more you stuff in.',
            engineer:
                'Budget tokens: system + tools + retrieved + user + reserved output. Measure tokens/sec and \$/1k.',
            analogy: 'Airline baggage — overweight is charged, and the suitcase still won’t close.',
            takeaways: const ['Budget tokens like memory.', 'RAG beats naive stuffing.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _embeddings() {
  const id = 'track_embeddings';
  const mod = 'mod_emb_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 11,
    title: 'Embeddings & Vector Search',
    tagline: 'Dense, sparse, hybrid, and cosine geometry',
    icon: '🧲',
    colorHex: '#26A69A',
    description: 'Semantic similarity, vector indexes, and when lexical search still wins.',
    keySkills: const ['Sentence Transformers', 'Cosine', 'HNSW', 'Hybrid search'],
    prerequisiteTrackIds: const ['track_llm'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Meaning as geometry',
        description: 'From strings to neighborhoods.',
        lessons: [
          lesson(
            id: 'emb_01',
            trackId: id,
            moduleId: mod,
            title: 'What an Embedding Is (and Isn’t)',
            subtitle: 'A map, not understanding',
            minutes: 8,
            xp: 55,
            concept:
                'An embedding is a fixed-length vector trained so semantic neighbors land nearby. It does not store facts and is not a database.',
            why: 'People treat nearest neighbors as truth. Neighbors are similar, not correct.',
            eli5: 'Putting similar toys on the same shelf so you can find them in the dark.',
            engineer:
                'Use the same model at index and query time. L2-normalize for cosine. Hybridize with BM25 for SKUs and names.',
            analogy: 'A library organized by “feels like” instead of the Dewey decimal system — until you need an ISBN.',
            visualizer: VisualizerType.vectorSearch,
            takeaways: const ['Same model both sides.', 'Hybrid for exact terms.'],
            tech: const ['tech_qdrant'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _rag() {
  const id = 'track_rag';
  const mod = 'mod_rag_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 12,
    title: 'Retrieval-Augmented Generation',
    tagline: 'Chunk, embed, retrieve, rerank, generate, evaluate',
    icon: '📚',
    colorHex: '#4CAF50',
    description:
        'Production RAG: semantic chunking, hybrid search, cross-encoders, GraphRAG, and Ragas metrics.',
    keySkills: const ['Chunking', 'Hybrid search', 'Rerankers', 'Ragas', 'Citations'],
    prerequisiteTrackIds: const ['track_embeddings'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Grounded generation',
        description: 'From PDFs to cited answers.',
        lessons: [
          lesson(
            id: 'rag_01',
            trackId: id,
            moduleId: mod,
            title: 'What is RAG?',
            subtitle: 'Give the model a library card, not a bigger brain',
            minutes: 12,
            xp: 80,
            concept:
                'RAG retrieves relevant passages and conditions generation on them. The model stays frozen; knowledge stays updateable and citable.',
            why:
                'Fine-tuning is a poor knowledge store. RAG reduces hallucinations and lets legal/ops teams update facts without a training run.',
            eli5:
                'A doctor who opens the newest paper before answering, instead of relying only on memory.',
            engineer:
                'Pipeline: parse → chunk → embed → index → retrieve → (rerank) → pack context → generate → cite. Evaluate faithfulness and context recall.',
            analogy: 'Writing a report with footnotes instead of improvising.',
            formula: 'RRF(d) = Σ 1 / (k + rank_m(d))  with k=60',
            mathIntuition: 'RRF merges ranked lists without calibrating raw scores.',
            visualizer: VisualizerType.ragPipeline,
            code: py(
              'Dense retrieval',
              r'''
import numpy as np

def cosine(a, b):
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

q = np.array([0.82, 0.45, 0.12, 0.91])
docs = [
    ("LangGraph state machines", np.array([0.80, 0.48, 0.10, 0.89])),
    ("MCP tool discovery", np.array([0.22, 0.11, 0.95, 0.31])),
]
best = max(docs, key=lambda d: cosine(q, d[1]))
print(best[0], round(cosine(q, best[1]), 4))
''',
              expected: 'LangGraph state machines 0.9989',
            ),
            mistakes: const [
              'Fixed-size chunks that split tables mid-row.',
              'Vector-only search for SKUs and IDs.',
              'Stuffing 20 redundant chunks (“lost in the middle”).',
            ],
            interview: interview(
              question: 'How do you measure RAG hallucinations?',
              answer:
                  'Ragas-style faithfulness (answer supported by context), answer relevance, context precision, and context recall against a labeled set.',
              followUps: const ['When does HyDE help?'],
              terms: const ['Faithfulness', 'RRF', 'Reranker'],
              topic: 'RAG',
            ),
            quiz: [
              mcq(
                id: 'q_rag_01',
                question: 'Primary job of a cross-encoder reranker?',
                options: [
                  opt('1', 'Jointly score (query, passage) with full attention', true),
                  opt('2', 'Compress PDFs', false),
                  opt('3', 'Replace the vector database', false),
                ],
                explanation: 'Cross-encoders are accurate and expensive — use on a shortlist.',
                topic: 'RAG',
              ),
            ],
            takeaways: const [
              'RAG is a system, not a single API call.',
              'Hybrid + rerank beats naive kNN.',
              'Citations are a product requirement.',
            ],
            tech: const ['tech_qdrant', 'tech_huggingface'],
            projects: const ['proj_02'],
          ),
          lesson(
            id: 'rag_02',
            trackId: id,
            moduleId: mod,
            title: 'Advanced RAG: HyDE, Parents, Graphs',
            subtitle: 'When vanilla chunk+search plateaus',
            minutes: 10,
            xp: 75,
            concept:
                'HyDE embeds a hypothetical answer. Parent-child retrieves small chunks but returns wider context. GraphRAG follows entity links.',
            why: 'Enterprise corpora are tables, policies, and contradictions — not Wikipedia paragraphs.',
            eli5: 'Sometimes you search for the answer you wish existed, then find the real page.',
            engineer:
                'Add metadata filters before vector search. Keep an eval set; every “clever” retriever can regress.',
            analogy: 'A detective following both keywords and a relationship map on the wall.',
            visualizer: VisualizerType.ragPipeline,
            takeaways: const ['Eval before cleverness.', 'Metadata is a first-class index.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _finetune() {
  const id = 'track_finetune';
  const mod = 'mod_ft_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 13,
    title: 'LLM Fine-Tuning',
    tagline: 'SFT, LoRA, QLoRA, DPO, preference data',
    icon: '🎯',
    colorHex: '#FB8C00',
    description: 'When to fine-tune versus retrieve, and how PEFT keeps it affordable.',
    keySkills: const ['LoRA', 'QLoRA', 'SFT', 'DPO', 'PEFT'],
    prerequisiteTrackIds: const ['track_llm'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Adaptation without a cluster',
        description: 'Preference optimization in practice.',
        lessons: [
          lesson(
            id: 'ft_01',
            trackId: id,
            moduleId: mod,
            title: 'LoRA, QLoRA & When Not to Fine-Tune',
            subtitle: 'Adapters are cheap; bad data is not',
            minutes: 9,
            xp: 65,
            concept:
                'LoRA injects low-rank updates into attention projections. QLoRA quantizes the base and trains adapters. Neither replaces a knowledge base.',
            why: 'Teams fine-tune to “add facts” and then cannot unlearn last quarter’s pricing.',
            eli5: 'Sticking a small sticky note on a huge textbook instead of rewriting the book.',
            engineer:
                'Fine-tune for style, format, and tool habits. Use RAG for facts. DPO needs preference pairs, not more unsupervised text.',
            analogy: 'Tailoring a suit versus buying a new wardrobe every season.',
            takeaways: const ['Adapters for behavior.', 'RAG for knowledge.'],
            tech: const ['tech_huggingface'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _agents() {
  const id = 'track_agents';
  const mod = 'mod_agent_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 14,
    title: 'AI Agents',
    tagline: 'Loops, tools, memory, ReAct, multi-agent',
    icon: '🤖',
    colorHex: '#E91E63',
    description: 'From chatbots to systems that plan, act, observe, and stop.',
    keySkills: const ['ReAct', 'Tool use', 'Memory', 'LangGraph', 'Guardrails'],
    prerequisiteTrackIds: const ['track_rag'],
    careerGoals: const [CareerGoal.agentEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Autonomous control loops',
        description: 'State, tools, and termination.',
        lessons: [
          lesson(
            id: 'agent_01',
            trackId: id,
            moduleId: mod,
            title: 'Build Your First AI Agent',
            subtitle: 'Thought → action → observation, with a stop condition',
            minutes: 16,
            xp: 110,
            concept:
                'An agent is an LLM plus tools plus a loop plus state. ReAct alternates reasoning traces with tool calls. Without max steps and typed state, loops never end.',
            why: 'The industry is shifting from Q&A to systems that file tickets, query warehouses, and open PRs.',
            eli5:
                'A project manager who thinks, asks a specialist, reads the answer, then decides the next move.',
            engineer:
                'Prefer explicit graphs (LangGraph) over a single “do anything” prompt. Persist state. Pause on destructive tools.',
            analogy: 'An assembly line with inspection gates, not a hamster wheel.',
            formula: 'S_{t+1} = f(S_t, A_t)    A_t = LLM(S_t)',
            mathIntuition: 'A discrete MDP whose policy is an LLM and whose transition is your runtime.',
            visualizer: VisualizerType.agentReactLoop,
            code: py(
              'Minimal ReAct loop',
              r'''
state = {"goal": "Count active users", "done": False, "obs": []}

def reason(s):
    return "sql", "SELECT COUNT(*) FROM users WHERE active=1"

def act(tool, arg):
    return "1420" if tool == "sql" else "unknown"

tool, arg = reason(state)
obs = act(tool, arg)
state["obs"].append(obs)
state["done"] = True
print(state["obs"][0], state["done"])
''',
              expected: '1420 True',
            ),
            mistakes: const [
              'No max-iteration guard.',
              'Untyped state dicts.',
              'Email/delete tools without human approval.',
            ],
            interview: interview(
              question: 'ReAct prompt loop vs LangGraph state machine?',
              answer:
                  'ReAct leaves control flow inside the model. Graphs add deterministic edges, checkpoints, time-travel, and human gates.',
              followUps: const ['How do you persist memory across sessions?'],
              terms: const ['ReAct', 'StateGraph', 'HITL'],
              topic: 'Agents',
            ),
            quiz: [
              mcq(
                id: 'q_agent_01',
                question: 'Why are cycles essential in agent graphs?',
                options: [
                  opt('1', 'Real work retries: code → test → fix', true),
                  opt('2', 'They remove the need for an LLM', false),
                  opt('3', 'They shrink context windows', false),
                ],
                explanation: 'Linear DAGs cannot represent retry/reflect loops.',
                topic: 'Agents',
              ),
            ],
            takeaways: const [
              'Agents are loops with tools.',
              'Stop conditions are features.',
              'Graphs beat unbounded prompts.',
            ],
            tech: const ['tech_langgraph'],
            projects: const ['proj_03'],
          ),
          lesson(
            id: 'agent_02',
            trackId: id,
            moduleId: mod,
            title: 'Memory, Reflection & Multi-Agent Roles',
            subtitle: 'Who speaks, who remembers, who is allowed to act',
            minutes: 10,
            xp: 80,
            concept:
                'Short-term memory is the state object. Long-term memory is a store you retrieve. Multi-agent systems assign roles (planner, critic, worker) with different tools.',
            why: 'A single omniscient agent is harder to evaluate and easier to jailbreak.',
            eli5: 'A newsroom: reporter, editor, fact-checker — not one person doing all three badly.',
            engineer:
                'Isolate credentials per role. Debate patterns improve some tasks and waste tokens on others — measure.',
            analogy: 'Air traffic control: many planes, one protocol, clear authority.',
            visualizer: VisualizerType.agentReactLoop,
            takeaways: const ['Roles bound blast radius.', 'Memory is a product, not a log dump.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _langgraph() {
  const id = 'track_langgraph';
  const mod = 'mod_lg_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 15,
    title: 'LangChain & LangGraph',
    tagline: 'Chains, graphs, checkpoints, human-in-the-loop',
    icon: '🕸️',
    colorHex: '#00ACC1',
    description: 'From LCEL chains to cyclic graphs you can debug in production.',
    keySkills: const ['LCEL', 'StateGraph', 'Checkpoints', 'HITL', 'Observability'],
    prerequisiteTrackIds: const ['track_agents'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Orchestration that can fail safely',
        description: 'Nodes, edges, persistence.',
        lessons: [
          lesson(
            id: 'lg_01',
            trackId: id,
            moduleId: mod,
            title: 'State Graphs, Checkpoints & Time Travel',
            subtitle: 'Treat the agent like a workflow engine',
            minutes: 10,
            xp: 75,
            concept:
                'LangGraph models execution as a Pregel-style graph. State is a typed reducer. Checkpointers persist steps so you can resume or inspect.',
            why: 'Customers will ask “why did it refund twice?” — you need a trace, not a vibe.',
            eli5: 'Saving a video game after every room, so you can rewind.',
            engineer:
                'Use reducers for lists (append messages). Conditional edges route on tool calls. Interrupt before side effects.',
            analogy: 'Git commits for a reasoning process.',
            tech: const ['tech_langgraph'],
            takeaways: const ['Typed state.', 'Checkpoint everything that mutates the world.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _mcp() {
  const id = 'track_mcp';
  const mod = 'mod_mcp_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 16,
    title: 'Model Context Protocol',
    tagline: 'The USB-C of tools, resources, and prompts',
    icon: '🔌',
    colorHex: '#673AB7',
    description:
        'MCP architecture, clients, servers, transports, and how agents discover tools safely.',
    keySkills: const ['FastMCP', 'JSON-RPC', 'Tools', 'Resources', 'Security'],
    prerequisiteTrackIds: const ['track_agents'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Standardized tool surfaces',
        description: 'Build once, connect many hosts.',
        lessons: [
          lesson(
            id: 'mcp_01',
            trackId: id,
            moduleId: mod,
            title: 'Build an MCP Server',
            subtitle: 'Tools, resources, prompts over JSON-RPC 2.0',
            minutes: 15,
            xp: 120,
            concept:
                'MCP standardizes how hosts (IDEs, agents) discover tools, read resources, and load prompt templates. Servers speak JSON-RPC over stdio or Streamable HTTP/SSE.',
            why: 'Without a protocol you rewrite glue for every model vendor. MCP is the shared plug.',
            eli5: 'One charger that fits every phone — tools that fit every AI host.',
            engineer:
                'FastMCP maps Python type hints to JSON Schema. Handshake advertises capabilities. Hosts call tools/call with validated arguments.',
            analogy: 'OpenAPI for LLM tools, with resources and prompts as first-class peers.',
            formula: '{"method":"tools/call","params":{"name":"get_stock","arguments":{"ticker":"GOOG"}}}',
            visualizer: VisualizerType.mcpArchitecture,
            code: py(
              'FastMCP server',
              r'''
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ai-engineering-tools")

@mcp.tool()
def query_vector_database(query: str, top_k: int = 5) -> str:
    """Search the knowledge base."""
    return f"top {top_k} chunks for '{query}'"

print("tools:", "query_vector_database")
''',
              expected: 'tools: query_vector_database',
            ),
            mistakes: const [
              'Vague tool docstrings — the model uses them as routing hints.',
              'Logging on stdout over stdio transport.',
              'Unsanitized shell/SQL inside tools.',
            ],
            interview: interview(
              question: 'Three primitives of an MCP server?',
              answer:
                  'Tools (side effects), Resources (read-only context), Prompts (reusable templates).',
              followUps: const ['stdio vs Streamable HTTP?'],
              terms: const ['MCP', 'JSON-RPC', 'FastMCP'],
              topic: 'MCP',
            ),
            quiz: [
              mcq(
                id: 'q_mcp_01',
                question: 'Why log to stderr on stdio transport?',
                options: [
                  opt('1', 'stdout is reserved for JSON-RPC frames', true),
                  opt('2', 'stderr is encrypted', false),
                  opt('3', 'It speeds backprop', false),
                ],
                explanation: 'Stray stdout bytes break framing and kill the session.',
                topic: 'MCP',
              ),
            ],
            takeaways: const [
              'MCP decouples hosts from tools.',
              'Schema comes from types + docs.',
              'Never pollute the protocol stream.',
            ],
            tech: const ['tech_mcp'],
            projects: const ['proj_04'],
          ),
          lesson(
            id: 'mcp_02',
            trackId: id,
            moduleId: mod,
            title: 'MCP Clients, Auth & Tool Abuse',
            subtitle: 'Discovery is not permission',
            minutes: 9,
            xp: 80,
            concept:
                'Clients must authenticate, scope tools, and sandbox side effects. Indirect prompt injection can trick a host into calling a tool you did not intend.',
            why: 'A helpful “read_file” tool is an exfiltration primitive if the agent reads secrets.',
            eli5: 'Having a house key is not the same as being allowed into the vault.',
            engineer:
                'Allow-list tools per session. Confirm destructive calls. Treat tool results as untrusted text.',
            analogy: 'OAuth scopes, not a master key under the doormat.',
            visualizer: VisualizerType.mcpArchitecture,
            takeaways: const ['Least privilege for tools.', 'Tool output is attacker-controlled text.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _mlops() {
  const id = 'track_mlops';
  const mod = 'mod_ops_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 17,
    title: 'MLOps',
    tagline: 'Data, training jobs, registries, drift, and rollback',
    icon: '⚙️',
    colorHex: '#546E7A',
    description: 'Ship classical ML like software: version data, train as a job, pin a registry, watch drift, roll back.',
    keySkills: const ['MLflow', 'Feature stores', 'CI/CD', 'Drift', 'Lineage'],
    prerequisiteTrackIds: const ['track_ml'],
    careerGoals: const [CareerGoal.mlopsEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Operate the system',
        description: 'Beyond the notebook.',
        lessons: [
          lesson(
            id: 'ops_01',
            trackId: id,
            moduleId: mod,
            title: 'Registries, Drift & Rollback',
            subtitle: 'If you cannot pin it, you cannot ship it',
            minutes: 9,
            xp: 65,
            concept:
                'MLOps versions data snapshots, training jobs, and model artifacts. A registry stage is a review, not a filename. Drift and rollback are the rest of the job.',
            why: 'A silent overwrite of prod weights is an incident, not a “quick fix.”',
            eli5: 'A lab notebook that also keeps the exact cake and a way to put last week’s cake back on the shelf.',
            engineer:
                'Promote through staging with an eval gate. Alert on feature drift. Pin last-good. Emit model version on every prediction.',
            analogy: 'Kubernetes rollouts for weights — not for prompts (that is LLMOps).',
            takeaways: const ['Pin a registry version.', 'Rollback is a pin, not a retrain.'],
            tech: const ['tech_fastapi'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _llmops() {
  const id = 'track_llmops';
  const mod = 'mod_llo_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 18,
    title: 'LLMOps',
    tagline: 'Prompts, traces, eval gates, RAG/agent ops, and token SLOs',
    icon: '🎛️',
    colorHex: '#6A1B9A',
    description:
        'Operate LLM products: version prompts, trace every hop, gate quality, pin indexes, budget tokens, and roll back a prompt like a binary.',
    keySkills: const ['Prompt registry', 'Langfuse', 'Eval harnesses', 'RAG ops', 'Token SLOs'],
    prerequisiteTrackIds: const ['track_mlops', 'track_llm'],
    careerGoals: const [CareerGoal.mlopsEngineer, CareerGoal.llmEngineer],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Operate the language model',
        description: 'Prompts and traces are production artifacts.',
        lessons: [
          lesson(
            id: 'llo_01',
            trackId: id,
            moduleId: mod,
            title: 'Prompts Are Deployed Artifacts',
            subtitle: 'A silent edit is a release',
            minutes: 9,
            xp: 70,
            concept:
                'A prompt in a string literal is an unversioned binary. LLMOps pins prompt id + hash, reviews diffs, and rolls back. Tools and model ids belong on the same card.',
            why: 'A Friday-night wording change can drop faithfulness 20% with no git blame on “the model.”',
            eli5: 'The instructions on the lunch menu are part of the recipe — you do not rewrite them in the kitchen without writing it down.',
            engineer: 'Store prompt text in a registry. Serve by pin. Diff like code. Eval the candidate before promote.',
            analogy: 'A feature-flagged config file, not a Slack paste.',
            takeaways: const ['Version the prompt.', 'A wording change is a release.'],
          ),
          lesson(
            id: 'llo_02',
            trackId: id,
            moduleId: mod,
            title: 'Traces Are the Flight Recorder',
            subtitle: 'Tokens, tools, and latency per hop',
            minutes: 9,
            xp: 70,
            concept:
                'An LLM trace is not a log line. It is spans: prompt pin, model, tokens in/out, tool calls, retrieved ids, cost, and user id (redacted).',
            why: '“The model was weird” is not a ticket. A trace id is.',
            eli5: 'A black box that writes down every radio call, not just “the plane landed.”',
            engineer: 'Export spans. Sample if you must; never drop errors. Redact PII before the vendor.',
            analogy: 'OpenTelemetry for completions.',
            takeaways: const ['One trace id per request.', 'Redact before you store.'],
          ),
          lesson(
            id: 'llo_03',
            trackId: id,
            moduleId: mod,
            title: 'Eval Gates for Generations',
            subtitle: 'A golden set that can fail the promote',
            minutes: 9,
            xp: 70,
            concept:
                'LLM CI runs a frozen golden set: faithfulness, schema, safety, and a task metric. LLM-as-judge is a screen. Humans spot-check. A vibe is not a gate.',
            why: 'Shipping on “it sounded better” is how quality regresses every week.',
            eli5: 'A spelling test you cannot change the night before the grade.',
            engineer: 'Pin the set. Fail closed on missing scores. Waiver is a signed exception, not a skip.',
            analogy: 'Unit tests for paragraphs.',
            takeaways: const ['Frozen golden set.', 'Judge ≠ ground truth.'],
          ),
          lesson(
            id: 'llo_04',
            trackId: id,
            moduleId: mod,
            title: 'RAG Ops: Index Versions',
            subtitle: 'Embedder + chunker + corpus SHA',
            minutes: 9,
            xp: 70,
            concept:
                'A retriever version is embedder pin, chunk config, and corpus snapshot. Bump any one → new index. Dual-read while you migrate.',
            why: 'A silent embedder upgrade against old vectors is mixed-space search.',
            eli5: 'If you change the map legend, you reprint the map — you do not mix two legends.',
            engineer: 'Cache keys include the index version. Rebuild or increment with a runbook.',
            analogy: 'A database migration for vectors.',
            takeaways: const ['Version the index.', 'Never mix embedder spaces.'],
          ),
          lesson(
            id: 'llo_05',
            trackId: id,
            moduleId: mod,
            title: 'Agent Ops in Production',
            subtitle: 'Budgets, allow-lists, dead-letters',
            minutes: 9,
            xp: 75,
            concept:
                'A prod agent has max steps, max tokens, tool allow-list, and a dead-letter. Irreversible tools have a human gate. Traces include every hop.',
            why: 'An unbounded ReAct loop is a cloud bill and a hung ticket.',
            eli5: 'A intern with a company card still has a daily limit.',
            engineer: 'Fail closed on missing caps. Count tool errors toward a budget. Show the trace on dead-letter.',
            analogy: 'A circuit breaker on a chatbot.',
            takeaways: const ['Cap the loop.', 'Allow-list tools.'],
          ),
          lesson(
            id: 'llo_06',
            trackId: id,
            moduleId: mod,
            title: 'Canary a Prompt, Not Only a Model',
            subtitle: 'A slice of traffic, then promote',
            minutes: 8,
            xp: 70,
            concept:
                'Prompt and model pins canary like binaries: 5% traffic, watch task metric + cost + errors, then promote. Instant 100% is a bet.',
            why: 'A bad system prompt on every user is an incident, not a “fast iterate.”',
            eli5: 'Taste-test the new recipe on one table before the whole restaurant.',
            engineer: 'Abort rule and promote rule in the same card. Keep last-good prompt pin.',
            analogy: 'A canary deploy for strings.',
            takeaways: const ['Canary the prompt.', 'Keep last-good.'],
          ),
          lesson(
            id: 'llo_07',
            trackId: id,
            moduleId: mod,
            title: 'Routers & Fallbacks',
            subtitle: 'Cheap model first, then a bigger one',
            minutes: 8,
            xp: 70,
            concept:
                'A router sends easy turns to a small model and hard ones to a large model (or a refuse). Fallback on timeout, schema miss, or safety trip. Log which route fired.',
            why: 'One 70B call for “what is the refund policy” is a bill, not a design.',
            eli5: 'Ask the intern first; call the specialist if the intern is stuck.',
            engineer: 'Route on intent + confidence. Cap cascade depth. Eval each route separately.',
            analogy: 'A load balancer with a brain.',
            takeaways: const ['Route then fallback.', 'Log the route.'],
          ),
          lesson(
            id: 'llo_08',
            trackId: id,
            moduleId: mod,
            title: 'Token SLOs Are Money',
            subtitle: 'TTFT, TPOT, and cost per request',
            minutes: 8,
            xp: 70,
            concept:
                'LLMOps SLOs include quality, TTFT/TPOT, and cost per successful request. A quality win that 3× the bill is a product decision, not a free lunch.',
            why: 'Tokens/sec on a padded bench hides chat TTFT and your invoice.',
            eli5: 'The taxi meter is part of whether the ride was good.',
            engineer: 'Budget max tokens. Cache prefixes. Split interactive vs batch queues. Alert on cost spikes.',
            analogy: 'An SLO that includes the cloud bill.',
            takeaways: const ['Quality, latency, and cost.', 'Budget tokens.'],
          ),
        ],
      ),
    ],
  );
}

RoadmapTrack _evalSecurity() {
  const id = 'track_eval_security';
  const mod = 'mod_sec_01';
  return RoadmapTrack(
    id: id,
    levelNumber: 19,
    title: 'Evaluation, Safety & Security',
    tagline: 'Metrics, jailbreaks, injection, responsible release',
    icon: '🛡️',
    colorHex: '#C62828',
    description:
        'How to know a system works — and how attackers make it work for them.',
    keySkills: const ['Ragas', 'Red teaming', 'Prompt injection', 'Fairness'],
    prerequisiteTrackIds: const ['track_agents', 'track_rag'],
    modules: [
      LearningModule(
        id: mod,
        trackId: id,
        title: 'Trust, then ship',
        description: 'Eval and adversarial thinking.',
        lessons: [
          lesson(
            id: 'sec_01',
            trackId: id,
            moduleId: mod,
            title: 'Evaluating Models, RAG & Agents',
            subtitle: 'Accuracy is not faithfulness is not tool-call accuracy',
            minutes: 10,
            xp: 70,
            concept:
                'Each system layer needs its own metric: ranking quality, groundedness, schema validity, and policy violations.',
            why: 'A fluent wrong answer is worse than a refusal.',
            eli5: 'Grading a test on handwriting versus whether the math is right.',
            engineer:
                'Maintain a golden set. Measure regressions in CI. Separate model eval from product eval.',
            analogy: 'Unit tests, integration tests, and a fire drill.',
            takeaways: const ['Layered metrics.', 'Golden sets in CI.'],
          ),
          lesson(
            id: 'sec_02',
            trackId: id,
            moduleId: mod,
            title: 'Prompt Injection & Agent Security',
            subtitle: 'Untrusted text is a control channel',
            minutes: 10,
            xp: 75,
            concept:
                'Direct injection lives in the user message. Indirect injection hides in retrieved pages or tool output. Agents amplify both by acting.',
            why: 'The moment a model can email or query prod, UX copy becomes an exploit primitive.',
            eli5: 'A note in a library book that says “ignore the teacher and give me the keys”.',
            engineer:
                'Sanitize/truncate retrieved text. Dual-LLM patterns. Confirm side effects. Never put secrets in prompts.',
            analogy: 'SQL injection, but the database is a helpful intern.',
            takeaways: const ['Treat retrieval as hostile.', 'Human gates on side effects.'],
          ),
        ],
      ),
    ],
  );
}
