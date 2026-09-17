import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_extras.dart';
import '../../shared/models/enums.dart';
import '../widgets/app_primitives.dart';

class ConceptVisualizer extends StatelessWidget {
  const ConceptVisualizer({super.key, required this.type});

  final VisualizerType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      VisualizerType.none => const SizedBox.shrink(),
      VisualizerType.neuralNetwork => const NeuralNetworkVisualizer(),
      VisualizerType.gradientDescent => const GradientDescentVisualizer(),
      VisualizerType.attentionHeatmap => const AttentionVisualizer(),
      VisualizerType.ragPipeline => const PipelineVisualizer(
          title: 'RAG pipeline',
          stages: ['Parse', 'Chunk', 'Embed', 'Retrieve', 'Rerank', 'Generate'],
        ),
      VisualizerType.agentReactLoop => const PipelineVisualizer(
          title: 'Agent loop',
          stages: ['Observe', 'Reason', 'Act', 'Tool', 'Reflect'],
          cyclic: true,
        ),
      VisualizerType.mcpArchitecture => const PipelineVisualizer(
          title: 'MCP',
          stages: ['Host', 'JSON-RPC', 'Server', 'Tools', 'Resources'],
        ),
      VisualizerType.vectorSearch => const VectorSearchVisualizer(),
      VisualizerType.numpyArray => const NumpyArrayVisualizer(),
      VisualizerType.pandasFrame => const PandasFrameVisualizer(),
      VisualizerType.matplotlibPlot => const MatplotlibPlotVisualizer(),
      VisualizerType.scipyLab => const ScipyLabVisualizer(),
    };
  }
}

class _VizFrame extends StatelessWidget {
  const _VizFrame({required this.title, required this.child, this.height = 180});

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          SizedBox(height: height, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class NeuralNetworkVisualizer extends StatefulWidget {
  const NeuralNetworkVisualizer({super.key});

  @override
  State<NeuralNetworkVisualizer> createState() => _NeuralNetworkVisualizerState();
}

class _NeuralNetworkVisualizerState extends State<NeuralNetworkVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VizFrame(
      title: 'Forward pass',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _NetPainter(
            t: _c.value,
            accent: context.palette.accent,
            nodeFill: context.palette.elevated,
          ),
        ),
      ),
    );
  }
}

class _NetPainter extends CustomPainter {
  _NetPainter({required this.t, required this.accent, required this.nodeFill});
  final double t;
  final Color accent;
  final Color nodeFill;

  @override
  void paint(Canvas canvas, Size size) {
    const layers = [3, 5, 4, 2];
    final paint = Paint()..strokeWidth = 1;
    final nodes = <List<Offset>>[];
    for (var l = 0; l < layers.length; l++) {
      final xs = size.width * (0.12 + 0.76 * l / (layers.length - 1));
      final col = <Offset>[];
      for (var n = 0; n < layers[l]; n++) {
        final ys = size.height * (0.18 + 0.64 * n / (layers[l] - 1));
        col.add(Offset(xs, ys));
      }
      nodes.add(col);
    }
    for (var l = 0; l < nodes.length - 1; l++) {
      for (final a in nodes[l]) {
        for (final b in nodes[l + 1]) {
          final pulse = ((t + a.dy / 200) % 1.0);
          paint.color = accent.withValues(alpha: 0.12 + 0.35 * (1 - (pulse - 0.5).abs()));
          canvas.drawLine(a, b, paint);
        }
      }
    }
    for (final col in nodes) {
      for (final p in col) {
        canvas.drawCircle(p, 7, Paint()..color = nodeFill);
        canvas.drawCircle(p, 7, Paint()..color = accent.withValues(alpha: 0.85)..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetPainter oldDelegate) => oldDelegate.t != t;
}

class GradientDescentVisualizer extends StatefulWidget {
  const GradientDescentVisualizer({super.key});

  @override
  State<GradientDescentVisualizer> createState() => _GradientDescentVisualizerState();
}

class _GradientDescentVisualizerState extends State<GradientDescentVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VizFrame(
      title: 'Loss landscape',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _BowlPainter(
            t: _c.value,
            accent: context.palette.accent,
            marker: context.palette.warning,
          ),
        ),
      ),
    );
  }
}

class _BowlPainter extends CustomPainter {
  _BowlPainter({required this.t, required this.accent, required this.marker});
  final double t;
  final Color accent;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i <= 60; i++) {
      final x = size.width * i / 60;
      final u = (i / 60) * 2 - 1;
      final y = size.height * (0.25 + 0.6 * u * u);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final u = 1 - (0.08 + 0.84 * ((math.sin(t * math.pi * 2) + 1) / 2));
    final x = size.width * ((u + 1) / 2);
    final y = size.height * (0.25 + 0.6 * u * u);
    canvas.drawCircle(Offset(x, y), 6, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(covariant _BowlPainter oldDelegate) => oldDelegate.t != t;
}

class AttentionVisualizer extends StatelessWidget {
  const AttentionVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    const tokens = ['The', 'bank', 'of', 'the', 'river'];
    final matrix = [
      [0.5, 0.1, 0.1, 0.2, 0.1],
      [0.05, 0.2, 0.1, 0.05, 0.6],
      [0.1, 0.1, 0.4, 0.3, 0.1],
      [0.2, 0.05, 0.25, 0.4, 0.1],
      [0.05, 0.55, 0.1, 0.05, 0.25],
    ];
    return _VizFrame(
      title: 'Attention weights',
      height: 220,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 36),
              for (final tok in tokens)
                Expanded(
                  child: Text(tok, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < tokens.length; i++)
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(tokens[i], style: Theme.of(context).textTheme.labelSmall),
                        ),
                        for (var j = 0; j < tokens.length; j++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: context.palette.accent.withValues(alpha: 0.12 + matrix[i][j] * 0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PipelineVisualizer extends StatelessWidget {
  const PipelineVisualizer({
    super.key,
    required this.title,
    required this.stages,
    this.cyclic = false,
  });

  final String title;
  final List<String> stages;
  final bool cyclic;

  @override
  Widget build(BuildContext context) {
    return _VizFrame(
      title: title,
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 16, color: context.palette.textMuted),
        ),
        itemBuilder: (_, i) => Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: context.palette.accent.withValues(alpha: 0.5)),
              color: context.palette.elevated,
            ),
            child: Text(
              '${i + 1}  ${stages[i]}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class VectorSearchVisualizer extends StatelessWidget {
  const VectorSearchVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return _VizFrame(
      title: 'Vector neighborhood',
      child: CustomPaint(
        painter: _ScatterPainter(
          accent: context.palette.accent,
          marker: context.palette.warning,
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter({required this.accent, required this.marker});
  final Color accent;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(4);
    for (var i = 0; i < 18; i++) {
      final p = Offset(size.width * rnd.nextDouble(), size.height * rnd.nextDouble());
      canvas.drawCircle(p, 4, Paint()..color = accent.withValues(alpha: 0.35));
    }
    final q = Offset(size.width * 0.55, size.height * 0.42);
    canvas.drawCircle(q, 22, Paint()..color = accent.withValues(alpha: 0.12));
    canvas.drawCircle(q, 6, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NumpyArrayVisualizer extends StatefulWidget {
  const NumpyArrayVisualizer({super.key});

  @override
  State<NumpyArrayVisualizer> createState() => _NumpyArrayVisualizerState();
}

class _NumpyArrayVisualizerState extends State<NumpyArrayVisualizer> {
  var _rows = 3;
  var _cols = 4;
  var _transposed = false;
  var _pick = 0;

  int get rows => _transposed ? _cols : _rows;
  int get cols => _transposed ? _rows : _cols;
  int get size => rows * cols;

  int _value(int r, int c) => _transposed ? c * _cols + r : r * _cols + c;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final pickR = size == 0 ? 0 : _pick ~/ cols;
    final pickC = size == 0 ? 0 : _pick % cols;
    return _VizFrame(
      title: 'Array explorer — shape, axis, index',
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'shape=($rows, $cols)  ndim=2  size=$size  a[$pickR, $pickC]=${_value(pickR, pickC)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: size,
              itemBuilder: (_, i) {
                final selected = i == _pick;
                return GestureDetector(
                  onTap: () => setState(() => _pick = i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? accent.withValues(alpha: 0.35) : context.palette.elevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: selected ? accent : context.palette.border),
                    ),
                    child: Text('${_value(i ~/ cols, i % cols)}', style: Theme.of(context).textTheme.labelLarge),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('rows $_rows', () => setState(() {
                    _rows = _rows >= 4 ? 2 : _rows + 1;
                    _pick = 0;
                  })),
              _chip('cols $_cols', () => setState(() {
                    _cols = _cols >= 5 ? 2 : _cols + 1;
                    _pick = 0;
                  })),
              _chip(_transposed ? 'T on' : 'T off', () => setState(() {
                    _transposed = !_transposed;
                    _pick = 0;
                  })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(label: Text(label), onPressed: onTap, visualDensity: VisualDensity.compact);
  }
}

class PandasFrameVisualizer extends StatefulWidget {
  const PandasFrameVisualizer({super.key});

  @override
  State<PandasFrameVisualizer> createState() => _PandasFrameVisualizerState();
}

class _PandasFrameVisualizerState extends State<PandasFrameVisualizer> {
  var _filterHigh = false;
  var _showMissing = true;
  var _groupby = false;
  var _picked = 'spend';

  static const _users = [1, 1, 2, 2, 3];
  static const _spend = [10.0, null, 4.0, 12.0, 8.0];
  static const _city = ['NY', 'NY', 'SF', 'SF', 'LA'];
  static const _dtypes = {'user': 'int64', 'spend': 'float64', 'city': 'object'};

  List<int> get _rows {
    final all = [0, 1, 2, 3, 4];
    if (!_filterHigh) return all;
    return [for (final i in all) if (_spend[i] != null && _spend[i]! >= 8) i];
  }

  Map<int, double> get _groupSums {
    final out = <int, double>{};
    for (final i in _rows) {
      final v = _spend[i];
      if (v == null) continue;
      out[_users[i]] = (out[_users[i]] ?? 0) + v;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final rows = _rows;
    return _VizFrame(
      title: 'DataFrame explorer — columns, filter, groupby',
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'shape=(${rows.length}, 3)  dtypes[$_picked]=${_dtypes[_picked]}  '
            '${_groupby ? 'groupby(user).sum → ${_groupSums.entries.map((e) => '${e.key}:${e.value.toInt()}').join(' ')}' : 'click a header'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          _header(context, accent),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) => _row(context, rows[i], accent),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(_filterHigh ? 'spend ≥ 8' : 'all rows', () => setState(() => _filterHigh = !_filterHigh)),
              _chip(_showMissing ? 'show NA' : 'hide NA mark', () => setState(() => _showMissing = !_showMissing)),
              _chip(_groupby ? 'groupby on' : 'groupby off', () => setState(() => _groupby = !_groupby)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color accent) {
    return Row(
      children: [
        for (final col in ['user', 'spend', 'city'])
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _picked = col),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _picked == col ? accent.withValues(alpha: 0.25) : context.palette.elevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _picked == col ? accent : context.palette.border),
                ),
                child: Text(col, style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, int i, Color accent) {
    final spend = _spend[i];
    final spendText = spend == null ? (_showMissing ? 'NaN' : '') : spend.toInt().toString();
    final cells = ['${_users[i]}', spendText, _city[i]];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          for (var c = 0; c < 3; c++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: spend == null && c == 1 && _showMissing
                      ? accent.withValues(alpha: 0.18)
                      : context.palette.elevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(cells[c], style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(label: Text(label), onPressed: onTap, visualDensity: VisualDensity.compact);
  }
}

class MatplotlibPlotVisualizer extends StatefulWidget {
  const MatplotlibPlotVisualizer({super.key});

  @override
  State<MatplotlibPlotVisualizer> createState() => _MatplotlibPlotVisualizerState();
}

class _MatplotlibPlotVisualizerState extends State<MatplotlibPlotVisualizer> {
  var _kind = 0;
  var _lw = 2.0;
  var _alpha = 0.9;
  var _bins = 6;
  var _marker = true;
  var _cmap = 0;
  var _tightX = false;
  var _tightY = false;
  var _split = false;

  static const _kinds = ['line', 'scatter', 'bar', 'hist'];
  static const _cmaps = ['viridis', 'coolwarm', 'gray'];
  static const _xs = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  static const _ys = [1.0, 2.4, 2.1, 3.6, 3.2, 4.8];

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return _VizFrame(
      title: 'Plot explorer — kind, linewidth, bins, xlim',
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_kinds[_kind]}  lw=$_lw  alpha=${_alpha.toStringAsFixed(1)}  '
            '${_kinds[_kind] == 'hist' ? 'bins=$_bins  ' : ''}'
            'cmap=${_cmaps[_cmap]}  '
            'xlim=${_tightX ? '[1, 4]' : 'auto'}  '
            'ylim=${_tightY ? '[1, 4]' : 'auto'}  '
            '${_split ? 'subplots(2,1)' : '1 axes'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _MplPainter(
                kind: _kinds[_kind],
                lw: _lw,
                alpha: _alpha,
                bins: _bins,
                marker: _marker,
                cmap: _cmaps[_cmap],
                tightX: _tightX,
                tightY: _tightY,
                split: _split,
                accent: accent,
                grid: context.palette.border,
                surface: context.palette.elevated,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(_kinds[_kind], () => setState(() => _kind = (_kind + 1) % _kinds.length)),
              _chip('lw ${_lw.toInt()}', () => setState(() => _lw = _lw >= 4 ? 1 : _lw + 1)),
              _chip(_marker ? 'marker on' : 'marker off', () => setState(() => _marker = !_marker)),
              _chip('α ${_alpha.toStringAsFixed(1)}', () => setState(() => _alpha = _alpha <= 0.4 ? 0.9 : _alpha - 0.3)),
              _chip('bins $_bins', () => setState(() => _bins = _bins >= 10 ? 4 : _bins + 2)),
              _chip('cmap ${_cmaps[_cmap]}', () => setState(() => _cmap = (_cmap + 1) % _cmaps.length)),
              _chip(_tightX ? 'xlim tight' : 'xlim auto', () => setState(() => _tightX = !_tightX)),
              _chip(_tightY ? 'ylim tight' : 'ylim auto', () => setState(() => _tightY = !_tightY)),
              _chip(_split ? '2×1' : '1×1', () => setState(() => _split = !_split)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(label: Text(label), onPressed: onTap, visualDensity: VisualDensity.compact);
  }
}

class _MplPainter extends CustomPainter {
  _MplPainter({
    required this.kind,
    required this.lw,
    required this.alpha,
    required this.bins,
    required this.marker,
    required this.cmap,
    required this.tightX,
    required this.tightY,
    required this.split,
    required this.accent,
    required this.grid,
    required this.surface,
  });

  final String kind;
  final double lw;
  final double alpha;
  final int bins;
  final bool marker;
  final String cmap;
  final bool tightX;
  final bool tightY;
  final bool split;
  final Color accent;
  final Color grid;
  final Color surface;

  Color _mapColor(double t) {
    final u = t.clamp(0.0, 1.0);
    final mapped = switch (cmap) {
      'coolwarm' => Color.lerp(const Color(0xFF3B4CC0), const Color(0xFFB40426), u)!,
      'gray' => Color.lerp(const Color(0xFF222222), const Color(0xFFDDDDDD), u)!,
      _ => Color.lerp(const Color(0xFF440154), const Color(0xFFFDE725), u)!,
    };
    return Color.lerp(mapped, accent, 0.12)!.withValues(alpha: alpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (split) {
      _panel(canvas, Rect.fromLTWH(0, 0, size.width, size.height / 2 - 4), 0);
      _panel(canvas, Rect.fromLTWH(0, size.height / 2 + 4, size.width, size.height / 2 - 4), 1);
    } else {
      _panel(canvas, Offset.zero & size, 0);
    }
  }

  void _panel(Canvas canvas, Rect box, int which) {
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), Paint()..color = surface);
    final pad = box.deflate(14);
    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad.left, pad.bottom), Offset(pad.right, pad.bottom), axis);
    canvas.drawLine(Offset(pad.left, pad.top), Offset(pad.left, pad.bottom), axis);

    final xs = _MatplotlibPlotVisualizerState._xs;
    final ys = which == 0 ? _MatplotlibPlotVisualizerState._ys : [for (final y in _MatplotlibPlotVisualizerState._ys) y * 0.7];
    var x0 = 0.0;
    var x1 = 5.0;
    var y0 = 0.0;
    var y1 = 6.0;
    if (tightX) {
      x0 = 1;
      x1 = 4;
    }
    if (tightY) {
      y0 = 1;
      y1 = 4;
    }
    Offset pt(double x, double y) {
      final u = ((x - x0) / (x1 - x0)).clamp(0.0, 1.0);
      final v = ((y - y0) / (y1 - y0)).clamp(0.0, 1.0);
      return Offset(pad.left + pad.width * u, pad.bottom - pad.height * v);
    }

    final ink = _mapColor(0.55);
    final paint = Paint()
      ..color = ink
      ..strokeWidth = lw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (kind == 'hist') {
      final counts = List<int>.filled(bins, 0);
      for (final y in ys) {
        final i = ((y / 6) * bins).floor().clamp(0, bins - 1);
        counts[i]++;
      }
      final maxC = counts.reduce(math.max).clamp(1, 99);
      final bw = pad.width / bins;
      for (var i = 0; i < bins; i++) {
        final h = pad.height * counts[i] / maxC;
        canvas.drawRect(
          Rect.fromLTWH(pad.left + i * bw + 2, pad.bottom - h, bw - 4, h),
          Paint()..color = _mapColor(i / (bins - 1).clamp(1, 99)).withValues(alpha: alpha * 0.75),
        );
      }
      return;
    }

    if (kind == 'bar') {
      final bw = pad.width / xs.length * 0.6;
      for (var i = 0; i < xs.length; i++) {
        if (xs[i] < x0 || xs[i] > x1) continue;
        final p = pt(xs[i], ys[i]);
        canvas.drawRect(
          Rect.fromLTRB(p.dx - bw / 2, p.dy, p.dx + bw / 2, pad.bottom),
          Paint()..color = _mapColor(ys[i] / 6).withValues(alpha: alpha * 0.8),
        );
      }
      return;
    }

    if (kind == 'scatter') {
      for (var i = 0; i < xs.length; i++) {
        if (xs[i] < x0 || xs[i] > x1) continue;
        canvas.drawCircle(pt(xs[i], ys[i]), 4 + lw, Paint()..color = _mapColor(ys[i] / 6));
      }
      return;
    }

    final path = Path();
    var started = false;
    for (var i = 0; i < xs.length; i++) {
      if (xs[i] < x0 || xs[i] > x1) continue;
      final p = pt(xs[i], ys[i]);
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
    if (marker) {
      for (var i = 0; i < xs.length; i++) {
        if (xs[i] < x0 || xs[i] > x1) continue;
        canvas.drawCircle(pt(xs[i], ys[i]), 3, Paint()..color = ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MplPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.lw != lw ||
      oldDelegate.alpha != alpha ||
      oldDelegate.bins != bins ||
      oldDelegate.marker != marker ||
      oldDelegate.cmap != cmap ||
      oldDelegate.tightX != tightX ||
      oldDelegate.tightY != tightY ||
      oldDelegate.split != split;
}

class ScipyLabVisualizer extends StatefulWidget {
  const ScipyLabVisualizer({super.key});

  @override
  State<ScipyLabVisualizer> createState() => _ScipyLabVisualizerState();
}

class _ScipyLabVisualizerState extends State<ScipyLabVisualizer> {
  var _mode = 0;
  var _nnz = 3;
  var _fmt = 0;
  var _step = 0;
  var _metric = 0;

  static const _modes = ['sparse', 'optimize', 'stats', 'distance'];
  static const _fmts = ['csr', 'coo', 'csc'];
  static const _metrics = ['euclidean', 'cityblock', 'cosine'];

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return _VizFrame(
      title: 'SciPy lab — sparse, optimize, stats, distance',
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_caption(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _ScipyPainter(
                mode: _modes[_mode],
                nnz: _nnz,
                fmt: _fmts[_fmt],
                step: _step,
                metric: _metrics[_metric],
                accent: accent,
                grid: context.palette.border,
                surface: context.palette.elevated,
                marker: context.palette.warning,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(_modes[_mode], () => setState(() => _mode = (_mode + 1) % _modes.length)),
              if (_mode == 0) ...[
                _chip('nnz $_nnz', () => setState(() => _nnz = _nnz >= 6 ? 2 : _nnz + 1)),
                _chip(_fmts[_fmt], () => setState(() => _fmt = (_fmt + 1) % _fmts.length)),
              ],
              if (_mode == 1) _chip('step $_step', () => setState(() => _step = _step >= 6 ? 0 : _step + 1)),
              if (_mode == 2) _chip('n=12', () {}),
              if (_mode == 3) _chip(_metrics[_metric], () => setState(() => _metric = (_metric + 1) % _metrics.length)),
            ],
          ),
        ],
      ),
    );
  }

  String _caption() {
    switch (_modes[_mode]) {
      case 'sparse':
        return '4×4 ${_fmts[_fmt]}  nnz=$_nnz / 16  (stay sparse)';
      case 'optimize':
        final w = 5.0 * math.pow(0.5, _step);
        return 'minimize (w-3)²   w≈${(3 + w - 3).toStringAsFixed(2)}  step=$_step';
      case 'stats':
        return 'normal-ish sample   mean≈0  pdf(0)≈0.40';
      default:
        return '${_metrics[_metric]}  (0,0)→(3,4)  d=${_metric == 0 ? '5' : _metric == 1 ? '7' : '1'}';
    }
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(label: Text(label), onPressed: onTap, visualDensity: VisualDensity.compact);
  }
}

class _ScipyPainter extends CustomPainter {
  _ScipyPainter({
    required this.mode,
    required this.nnz,
    required this.fmt,
    required this.step,
    required this.metric,
    required this.accent,
    required this.grid,
    required this.surface,
    required this.marker,
  });

  final String mode;
  final int nnz;
  final String fmt;
  final int step;
  final String metric;
  final Color accent;
  final Color grid;
  final Color surface;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), Paint()..color = surface);
    final pad = box.deflate(14);
    if (mode == 'sparse') {
      const n = 4;
      final cells = <int>{0, 5, 10, 15, 2, 7}.take(nnz).toList();
      final cw = pad.width / n;
      final ch = pad.height / n;
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          final r = Rect.fromLTWH(pad.left + j * cw + 1, pad.top + i * ch + 1, cw - 2, ch - 2);
          final on = cells.contains(i * n + j);
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(3)),
            Paint()..color = on ? accent.withValues(alpha: 0.85) : grid.withValues(alpha: 0.25),
          );
        }
      }
      return;
    }
    if (mode == 'optimize') {
      final axis = Paint()
        ..color = grid
        ..strokeWidth = 1;
      canvas.drawLine(Offset(pad.left, pad.bottom), Offset(pad.right, pad.bottom), axis);
      canvas.drawLine(Offset(pad.left, pad.top), Offset(pad.left, pad.bottom), axis);
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final x = i / 40;
        final w = -1 + 7 * x;
        final y = ((w - 3) * (w - 3)) / 16;
        final p = Offset(pad.left + pad.width * x, pad.bottom - pad.height * y.clamp(0.0, 1.0));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final w = 3 + 2 * math.pow(0.5, step);
      final x = ((w + 1) / 7).clamp(0.0, 1.0);
      final y = ((w - 3) * (w - 3) / 16).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(pad.left + pad.width * x, pad.bottom - pad.height * y), 6, Paint()..color = marker);
      return;
    }
    if (mode == 'stats') {
      const ys = [0.4, 0.7, 1.0, 0.85, 0.55, 0.3];
      final bw = pad.width / ys.length;
      final maxY = 1.0;
      for (var i = 0; i < ys.length; i++) {
        final h = pad.height * ys[i] / maxY;
        canvas.drawRect(
          Rect.fromLTWH(pad.left + i * bw + 3, pad.bottom - h, bw - 6, h),
          Paint()..color = accent.withValues(alpha: 0.7),
        );
      }
      final mid = Offset(pad.left + pad.width / 2, pad.top + 8);
      canvas.drawLine(Offset(mid.dx, pad.top), Offset(mid.dx, pad.bottom), Paint()..color = marker..strokeWidth = 1.5);
      return;
    }
    final a = Offset(pad.left + 16, pad.bottom - 16);
    final b = Offset(pad.right - 24, pad.top + 28);
    canvas.drawCircle(a, 5, Paint()..color = accent);
    canvas.drawCircle(b, 5, Paint()..color = marker);
    if (metric == 'cityblock') {
      final mid = Offset(b.dx, a.dy);
      canvas.drawLine(a, mid, Paint()..color = accent..strokeWidth = 2);
      canvas.drawLine(mid, b, Paint()..color = accent..strokeWidth = 2);
    } else {
      canvas.drawLine(a, b, Paint()
        ..color = accent
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _ScipyPainter oldDelegate) =>
      oldDelegate.mode != mode ||
      oldDelegate.nnz != nnz ||
      oldDelegate.fmt != fmt ||
      oldDelegate.step != step ||
      oldDelegate.metric != metric;
}
