import 'package:flutter/material.dart';

import '../../shared/models/content_models.dart';

/// Parses a [RoadmapTrack]'s `colorHex` (e.g. `#2979FF`) into a [Color],
/// falling back to a neutral blue when the hex is missing or malformed.
Color trackAccentColor(RoadmapTrack track) {
  final hex = track.colorHex.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16);
  return value == null ? const Color(0xFF2979FF) : Color(0xFF000000 | value);
}
