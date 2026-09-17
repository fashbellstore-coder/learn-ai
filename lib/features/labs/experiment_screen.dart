import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-attention decoder estimate. Decimal GB; excludes runtime overhead.
class InferenceBudget {
  const InferenceBudget({
    required this.parametersB,
    required this.weightBytes,
    required this.context,
    required this.concurrency,
    this.layers = 32,
    this.kvHeads = 8,
    this.headDimension = 128,
    this.cacheBytes = 2,
  });
  final double parametersB, weightBytes;
  final int context, concurrency, layers, kvHeads, headDimension, cacheBytes;
  double get weightsGB => parametersB * weightBytes;
  double get cacheGB =>
      2 *
      layers *
      kvHeads *
      headDimension *
      context *
      concurrency *
      cacheBytes /
      1e9;
  double get totalGB => weightsGB + cacheGB;
}

List<double> attentionWeights(double query, double temperature) {
  final scores = [-query / temperature, 0.0, query / temperature];
  final peak = scores.reduce(math.max);
  final exps = scores.map((s) => math.exp(s - peak)).toList();
  final sum = exps.reduce((a, b) => a + b);
  return exps.map((v) => v / sum).toList();
}

class ExperimentScreen extends StatefulWidget {
  const ExperimentScreen({super.key});
  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  double _parameters = 7, _context = 4096, _concurrency = 1, _bytes = 2;
  double _query = 1, _temperature = 1, _angle = 45;

  Widget control(
    String label,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> update,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: value.toStringAsFixed(1),
        onChanged: update,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final budget = InferenceBudget(
      parametersB: _parameters,
      weightBytes: _bytes,
      context: _context.round(),
      concurrency: _concurrency.round(),
    );
    final weights = attentionWeights(_query, _temperature);
    final cosine = math.cos(_angle * math.pi / 180);
    return Scaffold(
      appBar: AppBar(title: const Text('Experiment lab')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predict. Change. Observe. Explain.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These small mathematical models make the tradeoffs visible. Record a prediction before moving each control.',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Attention weights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'One-dimensional keys K = [−1, 0, 1]. Scores = Q × K / temperature; softmax turns scores into weights. This is a toy attention calculation.',
                  ),
                  control(
                    'Query Q: ${_query.toStringAsFixed(1)}',
                    _query,
                    -4,
                    4,
                    80,
                    (v) => setState(() => _query = v),
                  ),
                  control(
                    'Temperature: ${_temperature.toStringAsFixed(1)}',
                    _temperature,
                    0.2,
                    2,
                    18,
                    (v) => setState(() => _temperature = v),
                  ),
                  for (var i = 0; i < weights.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Key ${i - 1}: ${(weights[i] * 100).toStringAsFixed(1)}%',
                          ),
                          LinearProgressIndicator(
                            value: weights[i],
                            minHeight: 12,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Debug challenge: Why are all weights equal at Q = 0? Why does lowering temperature sharpen the distribution?',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Embedding geometry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Two unit vectors: a = [1, 0], b = [cos(angle), sin(angle)]. Cosine similarity is their normalized dot product. These are synthetic vectors, not sentence embeddings.',
                  ),
                  control(
                    'Angle: ${_angle.round()}°',
                    _angle,
                    0,
                    180,
                    180,
                    (v) => setState(() => _angle = v),
                  ),
                  Text(
                    'Cosine similarity: ${cosine.toStringAsFixed(3)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    'Experiment: Find orthogonal vectors. Then explain why multiplying a vector by a positive scalar leaves cosine similarity unchanged.',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Inference memory budget',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'A hypothetical decoder with 32 layers, 8 KV heads, head dimension 128 and a two-byte KV cache. Parameter count varies independently for this exercise; this is not a specific model configuration.',
                  ),
                  control(
                    'Parameters: ${_parameters.round()}B',
                    _parameters,
                    1,
                    70,
                    69,
                    (v) => setState(() => _parameters = v),
                  ),
                  control(
                    'Context tokens: ${_context.round()}',
                    _context,
                    1024,
                    32768,
                    31,
                    (v) => setState(() => _context = v),
                  ),
                  control(
                    'Concurrent sequences: ${_concurrency.round()}',
                    _concurrency,
                    1,
                    32,
                    31,
                    (v) => setState(() => _concurrency = v),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in {
                        0.5: '4-bit',
                        1.0: '8-bit',
                        2.0: '16-bit',
                        4.0: '32-bit',
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _bytes == entry.key,
                          onSelected: (_) => setState(() => _bytes = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Weights: ${budget.weightsGB.toStringAsFixed(2)} GB\nKV cache: ${budget.cacheGB.toStringAsFixed(2)} GB\nSubtotal: ${budget.totalGB.toStringAsFixed(2)} GB',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Weights = parameters × bytes. KV = 2 × layers × KV heads × head dimension × context × concurrent sequences × cache bytes. Decimal GB. Quantization metadata, activations, workspace and allocator overhead are excluded; allow additional headroom. Precision here changes weights only.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Break challenge: Fit 70B two-byte weights in 80 GB. Explain why changing concurrency cannot solve the weights-only limit. Compare quantization and sharding, then benchmark a real configuration before making throughput or latency claims.',
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
