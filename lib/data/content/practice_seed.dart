import '../../shared/models/content_models.dart';
import '../../shared/models/enums.dart';
import 'lesson_factory.dart';

class PracticeSeed {
  const PracticeSeed();

  List<QuizQuestion> drills() => [
        mcq(
          id: 'drill_relu',
          question: 'ReLU(0) equals',
          topic: 'Deep Learning',
          difficulty: Difficulty.easy,
          options: [opt('1', '0', true), opt('2', '1', false), opt('3', 'undefined', false)],
          explanation: 'max(0, 0) = 0.',
          type: QuizQuestionType.math,
        ),
        mcq(
          id: 'drill_cosine',
          question: 'Cosine similarity of a vector with itself is',
          topic: 'Embeddings',
          difficulty: Difficulty.easy,
          options: [opt('1', '1', true), opt('2', '0', false), opt('3', '-1', false)],
          explanation: 'Angle is zero; cos 0 = 1 (nonzero vectors).',
        ),
        mcq(
          id: 'drill_split',
          question: 'Test set is used to',
          topic: 'Data Science',
          difficulty: Difficulty.easy,
          options: [
            opt('1', 'Estimate generalization after model selection', true),
            opt('2', 'Tune learning rate repeatedly', false),
            opt('3', 'Fit the scaler', false),
          ],
          explanation: 'Val selects; test reports.',
        ),
        mcq(
          id: 'drill_temp',
          question: 'Lower temperature typically',
          topic: 'LLM Engineering',
          difficulty: Difficulty.medium,
          options: [
            opt('1', 'Makes next-token more peaked / less random', true),
            opt('2', 'Increases context length', false),
            opt('3', 'Disables the KV cache', false),
          ],
          explanation: 'T→0 approaches argmax.',
        ),
        mcq(
          id: 'drill_rrf',
          question: 'Reciprocal Rank Fusion combines',
          topic: 'RAG',
          difficulty: Difficulty.medium,
          options: [
            opt('1', 'Rank lists without calibrating raw scores', true),
            opt('2', 'Two loss functions in one backward pass', false),
            opt('3', 'CPU and TPU graphs', false),
          ],
          explanation: '1/(k+rank) is scale-free.',
        ),
        mcq(
          id: 'drill_lora',
          question: 'LoRA updates are',
          topic: 'Fine-tuning',
          difficulty: Difficulty.medium,
          options: [
            opt('1', 'Low-rank deltas on selected matrices', true),
            opt('2', 'A replacement for retrieval', false),
            opt('3', 'Full FP32 copies of every layer', false),
          ],
          explanation: 'That is the point of PEFT.',
        ),
        mcq(
          id: 'drill_gqa',
          question: 'GQA primarily reduces',
          topic: 'Inference',
          difficulty: Difficulty.hard,
          options: [
            opt('1', 'KV cache size', true),
            opt('2', 'Dataset size', false),
            opt('3', 'The number of GPUs required to add two integers', false),
          ],
          explanation: 'Shared K/V heads.',
        ),
        mcq(
          id: 'drill_mcp_prim',
          question: 'MCP primitives are',
          topic: 'MCP',
          difficulty: Difficulty.medium,
          options: [
            opt('1', 'Tools, resources, prompts', true),
            opt('2', 'Q, K, V only', false),
            opt('3', 'Pods, services, ingress', false),
          ],
          explanation: 'The spec’s three surfaces.',
        ),
        mcq(
          id: 'drill_injection',
          question: 'Indirect injection arrives via',
          topic: 'Security',
          difficulty: Difficulty.hard,
          options: [
            opt('1', 'Untrusted retrieved or tool text', true),
            opt('2', 'The learning rate schedule', false),
            opt('3', 'CUDA driver versions', false),
          ],
          explanation: 'The payload is in content the model reads.',
        ),
        mcq(
          id: 'drill_biasvar',
          question: 'High train, low val usually means',
          topic: 'Machine Learning',
          difficulty: Difficulty.easy,
          options: [
            opt('1', 'Overfitting', true),
            opt('2', 'Perfect calibration', false),
            opt('3', 'A finished product', false),
          ],
          explanation: 'Variance / memorization.',
        ),
      ];
}