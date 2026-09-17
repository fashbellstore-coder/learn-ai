import 'enums.dart';

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  AchievementBadge copyWith({bool? isUnlocked}) {
    return AchievementBadge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'isUnlocked': isUnlocked,
  };

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isUnlocked: json['isUnlocked'] as bool,
    );
  }
}

class Certificate {
  const Certificate({
    required this.id,
    required this.title,
    required this.track,
    required this.issueDate,
    required this.grade,
    required this.skillsEarned,
  });

  final String id;
  final String title;
  final String track;
  final String issueDate;
  final String grade;
  final List<String> skillsEarned;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'track': track,
    'issueDate': issueDate,
    'grade': grade,
    'skillsEarned': skillsEarned,
  };

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      title: json['title'] as String,
      track: json['track'] as String,
      issueDate: json['issueDate'] as String,
      grade: json['grade'] as String,
      skillsEarned: List<String>.from(json['skillsEarned'] as List),
    );
  }
}

class UserNote {
  const UserNote({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.content,
    required this.timestamp,
    this.tag = 'General',
  });

  final String id;
  final String lessonId;
  final String lessonTitle;
  final String content;
  final String timestamp;
  final String tag;

  Map<String, dynamic> toJson() => {
    'id': id,
    'lessonId': lessonId,
    'lessonTitle': lessonTitle,
    'content': content,
    'timestamp': timestamp,
    'tag': tag,
  };

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      lessonTitle: json['lessonTitle'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      tag: json['tag'] as String? ?? 'General',
    );
  }
}

class UserProfile {
  const UserProfile({
    this.id = 'usr_001',
    this.name = 'Learner',
    this.email = '',
    this.title = 'Learner',
    this.level = 1,
    this.xp = 0,
    this.nextLevelXp = 500,
    this.streakDays = 0,
    this.lastActiveDate = '',
    this.dailyGoalMinutes = 20,
    this.dailyMinutesSpent = 0,
    this.currentTrackId = 'track_python',
    this.goal = CareerGoal.aiEngineer,
    this.hasSelectedPath = false,
    this.skillLevel = SkillLevel.beginner,
    this.completedLessonIds = const {},
    this.bookmarkedLessonIds = const {},
    this.bookmarkedTechIds = const {},
    this.completedProjectIds = const {},
    this.quizScores = const {},
    this.earnedCertificates = const [],
    this.weakTopics = const [],
    this.badges = const [
      AchievementBadge(
        id: 'first_pass',
        title: 'First Forward Pass',
        description: 'Completed first neural network lesson',
        icon: '⚡',
        isUnlocked: false,
      ),
      AchievementBadge(
        id: 'streak_14',
        title: '14-Day Streak',
        description: 'Consistent learning for two weeks',
        icon: '🔥',
        isUnlocked: false,
      ),
      AchievementBadge(
        id: 'vector',
        title: 'Vector Explorer',
        description: 'Queried first cosine embedding index',
        icon: '🧭',
        isUnlocked: false,
      ),
      AchievementBadge(
        id: 'agent',
        title: 'Agent Commander',
        description: 'Built a multi-agent LangGraph pipeline',
        icon: '🤖',
        isUnlocked: false,
      ),
      AchievementBadge(
        id: 'mcp',
        title: 'MCP Architect',
        description: 'Deployed a custom Model Context Protocol tool',
        icon: '🔌',
        isUnlocked: false,
      ),
      AchievementBadge(
        id: 'grounded',
        title: 'Zero Hallucination',
        description: 'Scored 100% on a RAG evaluation quiz',
        icon: '🎯',
        isUnlocked: false,
      ),
    ],
    this.hasCompletedOnboarding = false,
    this.isAuthenticated = false,
    this.isPremium = false,
    this.notificationsEnabled = true,
  });

  final String id;
  final String name;
  final String email;
  final String title;
  final int level;
  final int xp;
  final int nextLevelXp;
  final int streakDays;
  final String lastActiveDate;
  final int dailyGoalMinutes;
  final int dailyMinutesSpent;
  final String currentTrackId;
  final CareerGoal goal;
  final bool hasSelectedPath;
  final SkillLevel skillLevel;
  final Set<String> completedLessonIds;
  final Set<String> bookmarkedLessonIds;
  final Set<String> bookmarkedTechIds;
  final Set<String> completedProjectIds;
  final Map<String, int> quizScores;
  final List<Certificate> earnedCertificates;
  final List<String> weakTopics;
  final List<AchievementBadge> badges;
  final bool hasCompletedOnboarding;
  final bool isAuthenticated;
  final bool isPremium;
  final bool notificationsEnabled;

  double get dailyProgress => dailyGoalMinutes == 0
      ? 0
      : (dailyMinutesSpent / dailyGoalMinutes).clamp(0, 1);

  UserProfile copyWith({
    String? name,
    String? email,
    String? title,
    int? level,
    int? xp,
    int? nextLevelXp,
    int? streakDays,
    String? lastActiveDate,
    int? dailyGoalMinutes,
    int? dailyMinutesSpent,
    String? currentTrackId,
    CareerGoal? goal,
    bool? hasSelectedPath,
    SkillLevel? skillLevel,
    Set<String>? completedLessonIds,
    Set<String>? bookmarkedLessonIds,
    Set<String>? bookmarkedTechIds,
    Set<String>? completedProjectIds,
    Map<String, int>? quizScores,
    List<Certificate>? earnedCertificates,
    List<String>? weakTopics,
    List<AchievementBadge>? badges,
    bool? hasCompletedOnboarding,
    bool? isAuthenticated,
    bool? isPremium,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      dailyMinutesSpent: dailyMinutesSpent ?? this.dailyMinutesSpent,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      goal: goal ?? this.goal,
      hasSelectedPath: hasSelectedPath ?? this.hasSelectedPath,
      skillLevel: skillLevel ?? this.skillLevel,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      bookmarkedLessonIds: bookmarkedLessonIds ?? this.bookmarkedLessonIds,
      bookmarkedTechIds: bookmarkedTechIds ?? this.bookmarkedTechIds,
      completedProjectIds: completedProjectIds ?? this.completedProjectIds,
      quizScores: quizScores ?? this.quizScores,
      earnedCertificates: earnedCertificates ?? this.earnedCertificates,
      weakTopics: weakTopics ?? this.weakTopics,
      badges: badges ?? this.badges,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPremium: isPremium ?? this.isPremium,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'title': title,
    'level': level,
    'xp': xp,
    'nextLevelXp': nextLevelXp,
    'streakDays': streakDays,
    'lastActiveDate': lastActiveDate,
    'dailyGoalMinutes': dailyGoalMinutes,
    'dailyMinutesSpent': dailyMinutesSpent,
    'currentTrackId': currentTrackId,
    'goal': goal.name,
    'hasSelectedPath': hasSelectedPath,
    'skillLevel': skillLevel.name,
    'completedLessonIds': completedLessonIds.toList(),
    'bookmarkedLessonIds': bookmarkedLessonIds.toList(),
    'bookmarkedTechIds': bookmarkedTechIds.toList(),
    'completedProjectIds': completedProjectIds.toList(),
    'quizScores': quizScores,
    'earnedCertificates': earnedCertificates.map((c) => c.toJson()).toList(),
    'weakTopics': weakTopics,
    'badges': badges.map((b) => b.toJson()).toList(),
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'isAuthenticated': isAuthenticated,
    'isPremium': isPremium,
    'notificationsEnabled': notificationsEnabled,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'usr_001',
      name: json['name'] as String? ?? 'Learner',
      email: json['email'] as String? ?? '',
      title: json['title'] as String? ?? 'AI Engineer Apprentice',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      nextLevelXp: json['nextLevelXp'] as int? ?? 500,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 20,
      dailyMinutesSpent: json['dailyMinutesSpent'] as int? ?? 0,
      currentTrackId: json['currentTrackId'] as String? ?? 'track_python',
      goal: CareerGoal.values.firstWhere(
        (g) => g.name == json['goal'],
        orElse: () => CareerGoal.aiEngineer,
      ),
      hasSelectedPath:
          json['hasSelectedPath'] as bool? ??
          (json['goal'] != null && json['goal'] != CareerGoal.aiEngineer.name),
      skillLevel: SkillLevel.values.firstWhere(
        (s) => s.name == json['skillLevel'],
        orElse: () => SkillLevel.beginner,
      ),
      completedLessonIds: Set<String>.from(
        json['completedLessonIds'] as List? ?? const [],
      ),
      bookmarkedLessonIds: Set<String>.from(
        json['bookmarkedLessonIds'] as List? ?? const [],
      ),
      bookmarkedTechIds: Set<String>.from(
        json['bookmarkedTechIds'] as List? ?? const [],
      ),
      completedProjectIds: Set<String>.from(
        json['completedProjectIds'] as List? ?? const [],
      ),
      quizScores: Map<String, int>.from(json['quizScores'] as Map? ?? const {}),
      earnedCertificates: (json['earnedCertificates'] as List? ?? const [])
          .map((e) => Certificate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weakTopics: List<String>.from(json['weakTopics'] as List? ?? const []),
      badges: (json['badges'] as List? ?? const [])
          .map(
            (e) =>
                AchievementBadge.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }
}
