library;

/// Learning currently focuses on the five STEM subject families.
/// Keep this classification at the catalog boundary because the category API
/// is also shared by community and blog features.
bool isStemLearningCategory(String name) {
  final normalized = name.trim().toLowerCase();
  return normalized.contains('math') ||
      normalized.contains('computer science') ||
      normalized.contains('technology') ||
      normalized.contains('engineering') ||
      normalized.contains('physics') ||
      normalized.contains('chemistry') ||
      normalized.contains('biology');
}

enum LessonDifficulty {
  easy,
  medium,
  hard,
  difficult;

  String get wire => name.toUpperCase();

  static LessonDifficulty? fromWire(String? value) {
    if (value == null) return null;
    for (final difficulty in values) {
      if (difficulty.wire == value.toUpperCase()) return difficulty;
    }
    return null;
  }
}

class LearningCategory {
  const LearningCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory LearningCategory.fromJson(Map<String, dynamic> json) =>
      LearningCategory(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.baseXp,
    required this.categoryId,
    required this.categoryName,
    required this.exerciseCount,
    required this.completed,
    required this.createdAt,
    this.grade,
    this.durationMinutes,
    this.progress,
  });

  final String id;
  final String title;
  final String description;
  final LessonDifficulty? difficulty;
  final int baseXp;
  final String? categoryId;
  final String categoryName;
  final int exerciseCount;
  final bool completed;
  final DateTime? createdAt;

  /// Nullable until the learning API adds grade metadata to lesson responses.
  final int? grade;

  /// Optional metadata supplied by newer learning API responses.
  /// UI code uses a conservative exercise-based estimate when duration is null.
  final int? durationMinutes;

  /// Normalized lesson progress from 0 to 1 when supplied by the API.
  final double? progress;

  factory LessonSummary.fromJson(Map<String, dynamic> json) => LessonSummary(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: LessonDifficulty.fromWire(json['difficulty'] as String?),
    baseXp: (json['baseXp'] as num?)?.toInt() ?? 0,
    categoryId: json['categoryId']?.toString(),
    categoryName: json['categoryName'] as String? ?? '',
    exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
    completed: json['completed'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    grade: _gradeFromJson(json['grade']),
    durationMinutes:
        (json['durationMinutes'] as num?)?.toInt() ??
        (json['estimatedMinutes'] as num?)?.toInt(),
    progress: _progressFromJson(json['progress']),
  );

  static int? _gradeFromJson(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return null;
  }

  static double? _progressFromJson(Object? value) {
    if (value is! num) return null;
    final normalized = value > 1 ? value / 100 : value.toDouble();
    return normalized.clamp(0, 1).toDouble();
  }
}

class LessonPage {
  const LessonPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<LessonSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  factory LessonPage.fromJson(Map<String, dynamic> json) => LessonPage(
    content: ((json['content'] as List?) ?? const [])
        .map(
          (item) =>
              LessonSummary.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    page:
        (json['number'] as num?)?.toInt() ??
        (json['page'] as num?)?.toInt() ??
        0,
    size: (json['size'] as num?)?.toInt() ?? 0,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

enum RoadmapUnitStatus {
  completed,
  current,
  skipped,
  locked;

  static RoadmapUnitStatus fromWire(Object? value) =>
      switch (value?.toString().toUpperCase()) {
        'COMPLETED' => completed,
        'SKIPPED' => skipped,
        'LOCKED' => locked,
        _ => current,
      };
}

enum RoadmapLessonStatus {
  completed,
  inProgress,
  available,
  skipped,
  locked;

  static RoadmapLessonStatus fromWire(Object? value) =>
      switch (value?.toString().toUpperCase()) {
        'COMPLETED' => completed,
        'IN_PROGRESS' => inProgress,
        'SKIPPED' => skipped,
        'LOCKED' => locked,
        _ => available,
      };
}

class LearningRoadmap {
  const LearningRoadmap({
    required this.categoryId,
    required this.categoryName,
    required this.completedLessons,
    required this.totalLessons,
    required this.progress,
    required this.currentLessonId,
    required this.activeDates,
    required this.units,
  });

  final String categoryId;
  final String categoryName;
  final int completedLessons;
  final int totalLessons;
  final double progress;
  final String? currentLessonId;
  final List<DateTime> activeDates;
  final List<RoadmapUnit> units;

  factory LearningRoadmap.fromJson(Map<String, dynamic> json) =>
      LearningRoadmap(
        categoryId: json['categoryId']?.toString() ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
        totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
        progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1),
        currentLessonId: json['currentLessonId']?.toString(),
        activeDates: ((json['activeDates'] as List?) ?? const [])
            .map((value) => DateTime.tryParse(value.toString()))
            .whereType<DateTime>()
            .toList(),
        units: ((json['units'] as List?) ?? const [])
            .map(
              (value) =>
                  RoadmapUnit.fromJson((value as Map).cast<String, dynamic>()),
            )
            .toList(),
      );
}

class RoadmapUnit {
  const RoadmapUnit({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.status,
    required this.completedLessons,
    required this.totalLessons,
    required this.skippable,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final int position;
  final RoadmapUnitStatus status;
  final int completedLessons;
  final int totalLessons;
  final bool skippable;
  final List<RoadmapLesson> lessons;

  factory RoadmapUnit.fromJson(Map<String, dynamic> json) => RoadmapUnit(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    position: (json['position'] as num?)?.toInt() ?? 0,
    status: RoadmapUnitStatus.fromWire(json['status']),
    completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
    totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
    skippable: json['skippable'] as bool? ?? false,
    lessons: ((json['lessons'] as List?) ?? const [])
        .map(
          (value) =>
              RoadmapLesson.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(),
  );
}

class RoadmapLesson {
  const RoadmapLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.baseXp,
    required this.rewardXp,
    required this.estimatedMinutes,
    required this.exerciseCount,
    required this.progress,
    required this.status,
    required this.current,
  });

  final String id;
  final String title;
  final String description;
  final LessonDifficulty? difficulty;
  final int baseXp;
  final int rewardXp;
  final int estimatedMinutes;
  final int exerciseCount;
  final double progress;
  final RoadmapLessonStatus status;
  final bool current;

  factory RoadmapLesson.fromJson(Map<String, dynamic> json) => RoadmapLesson(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: LessonDifficulty.fromWire(json['difficulty'] as String?),
    baseXp: (json['baseXp'] as num?)?.toInt() ?? 0,
    rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 0,
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
    exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
    progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1),
    status: RoadmapLessonStatus.fromWire(json['status']),
    current: json['current'] as bool? ?? false,
  );

  LessonSummary toSummary({
    required String categoryId,
    required String categoryName,
  }) => LessonSummary(
    id: id,
    title: title,
    description: description,
    difficulty: difficulty,
    baseXp: baseXp,
    categoryId: categoryId,
    categoryName: categoryName,
    exerciseCount: exerciseCount,
    completed: status == RoadmapLessonStatus.completed,
    createdAt: null,
    durationMinutes: estimatedMinutes,
    progress: progress,
  );
}

class LessonExercise {
  const LessonExercise({
    required this.id,
    required this.question,
    required this.difficulty,
    required this.points,
    required this.completed,
  });

  final String id;
  final String question;
  final LessonDifficulty? difficulty;
  final int points;
  final bool completed;

  factory LessonExercise.fromJson(Map<String, dynamic> json) => LessonExercise(
    id: json['id']?.toString() ?? '',
    question: json['question'] as String? ?? '',
    difficulty: LessonDifficulty.fromWire(json['difficulty'] as String?),
    points: (json['points'] as num?)?.toInt() ?? 0,
    completed: json['completed'] as bool? ?? false,
  );
}

class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.baseXp,
    required this.categoryId,
    required this.categoryName,
    required this.reflectionPrompt,
    required this.exercises,
  });

  final String id;
  final String title;
  final String description;
  final LessonDifficulty? difficulty;
  final int baseXp;
  final String? categoryId;
  final String categoryName;
  final String reflectionPrompt;
  final List<LessonExercise> exercises;

  factory LessonDetail.fromJson(Map<String, dynamic> json) => LessonDetail(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: LessonDifficulty.fromWire(json['difficulty'] as String?),
    baseXp: (json['baseXp'] as num?)?.toInt() ?? 0,
    categoryId: json['categoryId']?.toString(),
    categoryName: json['categoryName'] as String? ?? '',
    reflectionPrompt: json['reflectionPrompt'] as String? ?? '',
    exercises: ((json['exercises'] as List?) ?? const [])
        .map(
          (value) =>
              LessonExercise.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(),
  );
}

class LessonAnswerResult {
  const LessonAnswerResult({
    required this.exerciseId,
    required this.correct,
    required this.points,
    required this.message,
  });

  final String exerciseId;
  final bool correct;
  final int points;
  final String message;

  factory LessonAnswerResult.fromJson(Map<String, dynamic> json) =>
      LessonAnswerResult(
        exerciseId: json['exerciseId']?.toString() ?? '',
        correct: json['correct'] as bool? ?? false,
        points: (json['points'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
      );
}

class LessonCompletionResult {
  const LessonCompletionResult({required this.xpEarned});

  final int xpEarned;

  factory LessonCompletionResult.fromJson(Map<String, dynamic> json) =>
      LessonCompletionResult(
        xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      );
}
