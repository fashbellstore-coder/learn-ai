import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/content/asset_curriculum_loader.dart';
import 'data/content/practice_bank_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final trackOverrides = await const AssetCurriculumLoader().load();
  final pythonBank = await const PracticeBankLoader().load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        trackModuleOverridesProvider.overrideWithValue(trackOverrides),
        practiceBankDrillsProvider.overrideWithValue(pythonBank.drills),
        practiceBankInterviewsProvider.overrideWithValue(pythonBank.interviews),
      ],
      child: const LearnAiApp(),
    ),
  );
}
