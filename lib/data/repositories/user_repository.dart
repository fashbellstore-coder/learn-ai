import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/learning_math.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_models.dart';

class UserSession {
  const UserSession({
    required this.profile,
    required this.notes,
    required this.isDark,
  });

  final UserProfile profile;
  final List<UserNote> notes;
  final bool isDark;

  UserSession copyWith({
    UserProfile? profile,
    List<UserNote>? notes,
    bool? isDark,
  }) {
    return UserSession(
      profile: profile ?? this.profile,
      notes: notes ?? this.notes,
      isDark: isDark ?? this.isDark,
    );
  }
}

class UserController extends StateNotifier<UserSession> {
  UserController(this._prefs)
    : super(
        UserSession(
          profile: const UserProfile(),
          notes: const [],
          isDark: true,
        ),
      ) {
    _restore();
  }

  final SharedPreferences _prefs;
  final _streak = const StreakCalculator();

  static const _key = 'learn_ai.user.v1';

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(map['profile'] as Map),
      );
      final notes = (map['notes'] as List? ?? const [])
          .map((e) => UserNote.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = UserSession(
        profile: profile,
        notes: notes,
        isDark: map['isDark'] as bool? ?? true,
      );
    } catch (_) {
      // Keep seed profile if local cache is corrupt.
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'profile': state.profile.toJson(),
        'notes': state.notes.map((n) => n.toJson()).toList(),
        'isDark': state.isDark,
      }),
    );
  }

  Future<void> completeOnboarding({
    required String name,
    required SkillLevel level,
    required CareerGoal goal,
    required int dailyMinutes,
    required String firstTrackId,
    bool hasSelectedPath = true,
  }) async {
    state = state.copyWith(
      profile: state.profile.copyWith(
        name: name,
        skillLevel: level,
        goal: goal,
        hasSelectedPath: hasSelectedPath,
        dailyGoalMinutes: dailyMinutes,
        currentTrackId: firstTrackId,
        hasCompletedOnboarding: true,
        title: '${goal.title} track',
      ),
    );
    await _persist();
  }

  Future<void> updateProfileDetails({
    required String name,
    required String email,
  }) async {
    state = state.copyWith(
      profile: state.profile.copyWith(name: name, email: email),
    );
    await _persist();
  }

  Future<void> completeLesson(String lessonId, int xp, int minutes) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final p = state.profile;
    final already = p.completedLessonIds.contains(lessonId);
    final newXp = already ? p.xp : p.xp + xp;
    var level = p.level;
    var next = p.nextLevelXp;
    if (newXp >= next) {
      level += 1;
      next += 1500;
    }
    state = state.copyWith(
      profile: p.copyWith(
        completedLessonIds: {...p.completedLessonIds, lessonId},
        xp: newXp,
        level: level,
        nextLevelXp: next,
        dailyMinutesSpent: (p.dailyMinutesSpent + minutes).clamp(
          0,
          p.dailyGoalMinutes + 40,
        ),
        lastActiveDate: today,
        streakDays: _streak.nextStreak(
          currentStreak: p.streakDays,
          lastActive: p.lastActiveDate,
          today: today,
        ),
      ),
    );
    await _persist();
  }

  /// Records one quiz attempt for [lessonId], keeping the best score seen.
  /// Passing (score >= [passThreshold]) is derived from the best score, so
  /// a later low-scoring retake never un-passes a quiz already cleared.
  Future<void> recordQuizAttempt(
    String lessonId,
    int score, {
    int passThreshold = 70,
  }) async {
    final p = state.profile;
    final previousBest = p.quizScores[lessonId] ?? 0;
    if (score <= previousBest) return;
    state = state.copyWith(
      profile: p.copyWith(quizScores: {...p.quizScores, lessonId: score}),
    );
    await _persist();
  }

  int quizScore(String lessonId) => state.profile.quizScores[lessonId] ?? 0;

  bool isQuizPassed(String lessonId, {int passThreshold = 70}) =>
      quizScore(lessonId) >= passThreshold;

  Future<void> toggleLessonBookmark(String id) async {
    final set = {...state.profile.bookmarkedLessonIds};
    if (!set.add(id)) set.remove(id);
    state = state.copyWith(
      profile: state.profile.copyWith(bookmarkedLessonIds: set),
    );
    await _persist();
  }

  Future<void> toggleTechBookmark(String id) async {
    final set = {...state.profile.bookmarkedTechIds};
    if (!set.add(id)) set.remove(id);
    state = state.copyWith(
      profile: state.profile.copyWith(bookmarkedTechIds: set),
    );
    await _persist();
  }

  Future<void> addNote({
    required String lessonId,
    required String lessonTitle,
    required String content,
  }) async {
    final note = UserNote(
      id: const Uuid().v4(),
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      content: content,
      timestamp: 'Just now',
    );
    state = state.copyWith(notes: [note, ...state.notes]);
    await _persist();
  }

  Future<void> completeProject(String id, int xp) async {
    final p = state.profile;
    state = state.copyWith(
      profile: p.copyWith(
        completedProjectIds: {...p.completedProjectIds, id},
        xp: p.xp + xp,
      ),
    );
    await _persist();
  }

  Future<void> setGoal(CareerGoal goal) async {
    state = state.copyWith(
      profile: state.profile.copyWith(goal: goal, hasSelectedPath: true),
    );
    await _persist();
  }

  Future<void> setDailyGoal(int minutes) async {
    state = state.copyWith(
      profile: state.profile.copyWith(dailyGoalMinutes: minutes),
    );
    await _persist();
  }

  Future<void> setTheme(bool isDark) async {
    state = state.copyWith(isDark: isDark);
    await _persist();
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(
      profile: state.profile.copyWith(notificationsEnabled: enabled),
    );
    await _persist();
  }
}
