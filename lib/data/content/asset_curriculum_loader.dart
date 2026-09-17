import 'dart:convert';

import 'package:flutter/services.dart';

import '../../shared/models/content_models.dart';
import 'json_track_loader.dart';

/// The manifest is the single registration point for course content.
class AssetCurriculumLoader {
  const AssetCurriculumLoader();

  Future<Map<String, List<LearningModule>>> load() async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/content/courses.json'),
    ) as Map<String, dynamic>;
    final entries = (manifest['courses'] as List).cast<Map<String, dynamic>>();
    final loaded = await Future.wait(
      entries.map(
        (entry) => JsonTrackLoader(
          folder: entry['folder'] as String,
          trackId: entry['trackId'] as String,
          moduleCount: entry['moduleCount'] as int,
          idPrefix: entry['idPrefix'] as String,
        ).load(strict: true),
      ),
    );
    final result = <String, List<LearningModule>>{};
    final lessonIds = <String>{};
    for (var i = 0; i < entries.length; i++) {
      final id = entries[i]['trackId'] as String;
      if (result.containsKey(id)) {
        throw FormatException('Duplicate course: $id');
      }
      if (loaded[i].isEmpty) {
        throw FormatException('Course has no modules: $id');
      }
      final moduleIds = <String>{};
      for (final module in loaded[i]) {
        if (!moduleIds.add(module.id)) {
          throw FormatException('Duplicate module: ${module.id}');
        }
        for (final lesson in module.lessons) {
          if (!lessonIds.add(lesson.id)) {
            throw FormatException('Duplicate lesson: ${lesson.id}');
          }
        }
      }
      result[id] = loaded[i];
    }
    return result;
  }
}
