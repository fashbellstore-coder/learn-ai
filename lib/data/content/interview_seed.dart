import '../../shared/models/content_models.dart';
import 'lesson_factory.dart';

class InterviewSeed {
  const InterviewSeed();

  List<InterviewItem> bank() => [
        interview(
          topic: 'Python',
          question: 'Explain GIL implications for data-parallel preprocessing.',
          answer:
              'The GIL serializes bytecode. Use multiprocessing, native extensions (NumPy), or release the GIL in C for CPU-bound work. I/O-bound work is fine with threads/async.',
          terms: const ['GIL', 'multiprocessing'],
          followUps: const ['When do you pick Ray vs a process pool?'],
        ),
        interview(
          topic: 'Machine Learning',
          question: 'How do you detect data leakage in a shipped model?',
          answer:
              'Compare offline vs online feature distributions, inspect pipeline fit scope, and look for target-derived features. Time-based backtests catch future information.',
          terms: const ['Leakage', 'Backtest'],
        ),
        interview(
          topic: 'Deep Learning',
          question: 'Walk through backprop for a two-layer MLP.',
          answer:
              'Forward stores activations. Loss gradient w.r.t. logits flows through softmax. Each layer applies the local Jacobian and the previous activation as the outer product for dW.',
          terms: const ['Chain rule', 'Autograd'],
        ),
        interview(
          topic: 'Transformers',
          question: 'Why does Grouped-Query Attention reduce inference memory?',
          answer:
              'Multiple query heads share a smaller set of K/V heads, shrinking the KV cache roughly by the grouping factor while keeping query expressiveness.',
          terms: const ['GQA', 'KV cache'],
        ),
        interview(
          topic: 'RAG',
          question: 'Design a RAG system for a 10k-page policy corpus.',
          answer:
              'Layout-aware parse, hierarchical chunking, hybrid index, metadata filters (jurisdiction, date), rerank, citation UI, and a faithfulness eval set owned by legal.',
          terms: const ['Hybrid', 'Citations', 'Faithfulness'],
        ),
        interview(
          topic: 'Agents',
          question: 'How would you stop an agent from looping forever?',
          answer:
              'Hard step limits, token budgets, cycle detection on state hashes, tool allow-lists, and human interrupts on side-effecting nodes.',
          terms: const ['Guardrails', 'HITL'],
        ),
        interview(
          topic: 'System Design',
          question: 'Design a multi-tenant RAG platform.',
          answer:
              'Per-tenant collections or namespaces, authZ on retrieve, isolated embedding keys, tracing, quota, and a promotion flow for chunker/prompt versions.',
          terms: const ['Multi-tenant', 'AuthZ', 'Quotas'],
        ),
        interview(
          topic: 'MLOps',
          question: 'What do you version besides weights?',
          answer:
              'Data snapshots, feature code, training config, evaluation sets, prompts, tool schemas, and the exact runtime image.',
          terms: const ['Lineage', 'Prompts'],
        ),
        interview(
          topic: 'Computer Vision',
          question: 'When is detection the wrong task?',
          answer:
              'If a single object fills the frame and you only need a label, classification is cheaper to label and serve. Detection is for multiple instances or localization.',
          terms: const ['Detection', 'Label cost'],
        ),
        interview(
          topic: 'Fine-tuning',
          question: 'SFT or RAG for last quarter’s pricing?',
          answer:
              'RAG (or a database). Fine-tuning is a poor knowledge store and is hard to unlearn. Use SFT/DPO for style, format, and tool habits.',
          terms: const ['RAG', 'SFT'],
        ),
        interview(
          topic: 'Inference',
          question: 'What dominates VRAM at long context with many users?',
          answer:
              'The KV cache, not just the weights. PagedAttention, GQA, concurrency caps, and quantization of KV are the levers.',
          terms: const ['KV cache', 'PagedAttention'],
        ),
        interview(
          topic: 'Security',
          question: 'How does indirect prompt injection reach a tool?',
          answer:
              'A retrieved or tool-returned document contains instructions. The agent treats them as policy and calls a powerful tool. Defense: delimit untrusted text, allow-list, confirm side effects.',
          terms: const ['Indirect injection', 'Tools'],
        ),
        interview(
          topic: 'MCP',
          question: 'Why is stdout sacred on stdio transport?',
          answer:
              'The stream is JSON-RPC frames. Logs on stdout corrupt framing and drop the session. Log to stderr.',
          terms: const ['stdio', 'JSON-RPC'],
        ),
        interview(
          topic: 'Evaluation',
          question: 'Why is fluency a dangerous metric for RAG?',
          answer:
              'A fluent wrong answer is worse than a refusal. Measure faithfulness and citation validity, not only BLEU or “sounds good.”',
          terms: const ['Faithfulness', 'Fluency'],
        ),
      ];
}
