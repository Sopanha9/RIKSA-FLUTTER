import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';

class _FakeLearningApi implements LearningApi {
  @override
  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required String reflectionText,
  }) => throw UnimplementedError();

  @override
  Future<List<LearningCategory>> categories() async => const [
    LearningCategory(id: 'math', name: 'Mathematics'),
  ];

  @override
  Future<LessonPage> listLessons({
    String? categoryId,
    LessonDifficulty? difficulty,
    int? grade,
    int page = 0,
    int size = 20,
  }) async => LessonPage(
    content: const [
      LessonSummary(
        id: 'lesson-1',
        title: 'Derivatives',
        description: 'Introduction to derivatives.',
        difficulty: LessonDifficulty.easy,
        baseXp: 20,
        categoryId: 'math',
        categoryName: 'Mathematics',
        exerciseCount: 2,
        completed: false,
        createdAt: null,
      ),
    ],
    page: page,
    size: size,
    totalElements: 1,
    totalPages: 1,
  );

  @override
  Future<LessonDetail> lesson(String lessonId) => throw UnimplementedError();

  @override
  Future<LearningRoadmap> roadmap(String categoryId) =>
      throw UnimplementedError();

  @override
  Future<void> resumeRoadmapUnit(String unitId) => throw UnimplementedError();

  @override
  Future<void> skipRoadmapUnit(String unitId) => throw UnimplementedError();

  @override
  Future<void> startLesson(String lessonId) => throw UnimplementedError();

  @override
  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) => throw UnimplementedError();
}

void main() {
  test('initializes state before starting the first catalog load', () async {
    final container = ProviderContainer(
      overrides: [learningApiProvider.overrideWithValue(_FakeLearningApi())],
    );
    addTearDown(container.dispose);

    expect(container.read(lessonCatalogProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(lessonCatalogProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.lessons.single.title, 'Derivatives');
    expect(state.categories.single.name, 'Mathematics');
  });
}
