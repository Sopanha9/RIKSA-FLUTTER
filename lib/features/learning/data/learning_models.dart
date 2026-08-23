library;

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
  );

  static int? _gradeFromJson(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return null;
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
