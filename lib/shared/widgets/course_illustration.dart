import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/models/content_models.dart';

/// The handful of decorative motifs drawn on library cards. Picked per
/// course from its id/title/tagline — see [courseIllustrationKind].
enum CourseIllustrationKind { math, database, data, code, ai, cloud, security, generic }

CourseIllustrationKind courseIllustrationKind(RoadmapTrack track) {
  final haystack =
      '${track.id} ${track.title} ${track.tagline}'.toLowerCase();
  bool has(List<String> words) => words.any(haystack.contains);

  if (has(['sql', 'database', 'vectordb', 'db'])) {
    return CourseIllustrationKind.database;
  }
  if (has(['math', 'algebra', 'calculus', 'statistic', 'probability'])) {
    return CourseIllustrationKind.math;
  }
  if (has(['cloud', 'devops', 'kubernetes', 'docker', 'enterprise', 'infra'])) {
    return CourseIllustrationKind.cloud;
  }
  if (has(['security', 'cyber'])) {
    return CourseIllustrationKind.security;
  }
  if (has([
    'ml', 'ai', 'neural', 'deep learning', 'transformer', 'llm', 'nlp',
    'genai', 'agent', 'langgraph', 'mcp', 'embedding', 'rag', 'hugging face',
    'reasoning', 'multimodal', 'vision', 'pytorch', 'tensorflow',
    'distributed', 'mlops', 'llmops', 'eval', 'fine-tun', 'finetun',
  ])) {
    return CourseIllustrationKind.ai;
  }
  if (has(['data science', 'pandas', 'numpy', 'analytics', 'dataframe', 'eda', 'scikit'])) {
    return CourseIllustrationKind.data;
  }
  if (has([
    'python', 'java', 'javascript', 'rust', 'django', 'flask', 'aspnet',
    'solidity', 'assembly', 'vba', 'zig', 'bash', 'xml', 'software',
    'programming', 'app dev', 'swe', 'code',
  ])) {
    return CourseIllustrationKind.code;
  }
  return CourseIllustrationKind.generic;
}

/// A small vector motif drawn behind a library card, bleeding off its right
/// edge. Colors derive entirely from [color] so it follows the active theme.
class CourseIllustration extends StatelessWidget {
  const CourseIllustration({
    super.key,
    required this.kind,
    required this.color,
  });

  final CourseIllustrationKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CourseIllustrationPainter(kind: kind, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _CourseIllustrationPainter extends CustomPainter {
  _CourseIllustrationPainter({required this.kind, required this.color});

  final CourseIllustrationKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.72, size.height * 0.5);
    switch (kind) {
      case CourseIllustrationKind.math:
        _paintMath(canvas, origin, size);
      case CourseIllustrationKind.database:
        _paintDatabase(canvas, origin, size);
      case CourseIllustrationKind.data:
        _paintData(canvas, origin, size);
      case CourseIllustrationKind.code:
        _paintCode(canvas, origin, size);
      case CourseIllustrationKind.ai:
        _paintAi(canvas, origin, size);
      case CourseIllustrationKind.cloud:
        _paintCloud(canvas, origin, size);
      case CourseIllustrationKind.security:
        _paintSecurity(canvas, origin, size);
      case CourseIllustrationKind.generic:
        _paintGeneric(canvas, origin, size);
    }
  }

  void _paintMath(Canvas canvas, Offset o, Size size) {
    final r = size.height * 0.34;
    final fill = Paint()..color = color.withValues(alpha: 0.16);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final diamond = Path()
      ..moveTo(o.dx, o.dy - r)
      ..lineTo(o.dx + r, o.dy)
      ..lineTo(o.dx, o.dy + r)
      ..lineTo(o.dx - r, o.dy)
      ..close();
    canvas.drawPath(diamond, fill);
    canvas.drawPath(diamond, stroke);
    canvas.drawLine(Offset(o.dx, o.dy - r), Offset(o.dx, o.dy + r), stroke);
    canvas.drawLine(Offset(o.dx - r, o.dy), Offset(o.dx + r, o.dy), stroke);
    canvas.drawCircle(
      Offset(o.dx + r * 0.9, o.dy - r * 0.95),
      4,
      Paint()..color = color.withValues(alpha: 0.7),
    );
  }

  void _paintDatabase(Canvas canvas, Offset o, Size size) {
    final w = size.height * 0.5;
    final ellipseH = size.height * 0.13;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.14);
    final top = o.dy - size.height * 0.28;
    for (var i = 0; i < 3; i++) {
      final y = top + i * (ellipseH * 1.35);
      final rect = Rect.fromCenter(
        center: Offset(o.dx, y),
        width: w,
        height: ellipseH,
      );
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect, stroke);
    }
    canvas.drawLine(
      Offset(o.dx - w / 2, top),
      Offset(o.dx - w / 2, top + 2 * ellipseH * 1.35),
      stroke,
    );
    canvas.drawLine(
      Offset(o.dx + w / 2, top),
      Offset(o.dx + w / 2, top + 2 * ellipseH * 1.35),
      stroke,
    );
  }

  void _paintData(Canvas canvas, Offset o, Size size) {
    final nodes = <Offset>[
      Offset(o.dx - size.height * 0.28, o.dy - size.height * 0.22),
      Offset(o.dx + size.height * 0.12, o.dy - size.height * 0.3),
      Offset(o.dx + size.height * 0.3, o.dy - size.height * 0.02),
      Offset(o.dx - size.height * 0.1, o.dy + size.height * 0.06),
      Offset(o.dx + size.height * 0.05, o.dy + size.height * 0.3),
    ];
    final line = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.4;
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], line);
    }
    canvas.drawLine(nodes[0], nodes[3], line);
    final dot = Paint()..color = color.withValues(alpha: 0.75);
    for (final n in nodes) {
      canvas.drawCircle(n, 3.2, dot);
    }
  }

  void _paintCode(Canvas canvas, Offset o, Size size) {
    final w = size.height * 0.62;
    final h = size.height * 0.46;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final back = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(o.dx + 6, o.dy - 4),
        width: w,
        height: h,
      ),
      const Radius.circular(8),
    );
    final front = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(o.dx - 8, o.dy + 8), width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(back, fill);
    canvas.drawRRect(back, stroke);
    canvas.drawRRect(front, fill);
    canvas.drawRRect(front, stroke);
    final lineStroke = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final fx = front.center.dx - w * 0.28;
    final fy = front.center.dy - h * 0.18;
    canvas.drawLine(Offset(fx, fy), Offset(fx + w * 0.32, fy), lineStroke);
    canvas.drawLine(
      Offset(fx, fy + 10),
      Offset(fx + w * 0.2, fy + 10),
      lineStroke,
    );
  }

  void _paintAi(Canvas canvas, Offset o, Size size) {
    final w = size.height * 0.44;
    final h = size.height * 0.4;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.14);
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(center: o, width: w, height: h),
      const Radius.circular(12),
    );
    canvas.drawRRect(head, fill);
    canvas.drawRRect(head, stroke);
    final eye = Paint()..color = color.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(o.dx - w * 0.2, o.dy), 3, eye);
    canvas.drawCircle(Offset(o.dx + w * 0.2, o.dy), 3, eye);
    canvas.drawLine(
      Offset(o.dx, o.dy - h / 2),
      Offset(o.dx, o.dy - h / 2 - 10),
      stroke,
    );
    canvas.drawCircle(Offset(o.dx, o.dy - h / 2 - 12), 2.6, eye);
  }

  void _paintCloud(Canvas canvas, Offset o, Size size) {
    final fill = Paint()..color = color.withValues(alpha: 0.16);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final r = size.height * 0.14;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(o.dx - r * 0.9, o.dy + r * 0.3), radius: r * 0.85))
      ..addOval(Rect.fromCircle(center: Offset(o.dx + r * 0.4, o.dy - r * 0.4), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(o.dx + r * 1.5, o.dy + r * 0.2), radius: r * 0.8))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(o.dx + r * 0.2, o.dy + r * 0.6),
            width: r * 3,
            height: r * 0.9,
          ),
          Radius.circular(r * 0.4),
        ),
      );
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _paintSecurity(Canvas canvas, Offset o, Size size) {
    final w = size.height * 0.36;
    final h = size.height * 0.46;
    final fill = Paint()..color = color.withValues(alpha: 0.16);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..moveTo(o.dx, o.dy - h / 2)
      ..lineTo(o.dx + w / 2, o.dy - h * 0.32)
      ..lineTo(o.dx + w / 2, o.dy + h * 0.1)
      ..quadraticBezierTo(o.dx + w / 2, o.dy + h * 0.42, o.dx, o.dy + h / 2)
      ..quadraticBezierTo(o.dx - w / 2, o.dy + h * 0.42, o.dx - w / 2, o.dy + h * 0.1)
      ..lineTo(o.dx - w / 2, o.dy - h * 0.32)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    final check = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(o.dx - w * 0.18, o.dy),
      Offset(o.dx - w * 0.02, o.dy + h * 0.14),
      check,
    );
    canvas.drawLine(
      Offset(o.dx - w * 0.02, o.dy + h * 0.14),
      Offset(o.dx + w * 0.22, o.dy - h * 0.14),
      check,
    );
  }

  void _paintGeneric(Canvas canvas, Offset o, Size size) {
    final blob = Paint()..color = color.withValues(alpha: 0.16);
    canvas.drawCircle(o, size.height * 0.32, blob);
    canvas.drawCircle(
      Offset(o.dx + size.height * 0.24, o.dy - size.height * 0.18),
      size.height * 0.14,
      Paint()..color = color.withValues(alpha: 0.22),
    );
    final ring = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(o, size.height * 0.32, ring);
    final orbitR = size.height * 0.4;
    canvas.drawCircle(
      Offset(
        o.dx + orbitR * math.cos(0.9),
        o.dy + orbitR * math.sin(0.9),
      ),
      3,
      Paint()..color = color.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _CourseIllustrationPainter oldDelegate) {
    return kind != oldDelegate.kind || color != oldDelegate.color;
  }
}
