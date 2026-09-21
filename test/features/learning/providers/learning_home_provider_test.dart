import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_design.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLearningHomeApi implements LearningApi {
  _FakeLearningHomeApi(this._categories);
  final List<LearningCategory> _categories;

  @override
  Future<List<LearningCategory>> categories() async => _categories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LearningRoadmap _fakeRoadmap({
  required String categoryId,
  required String categoryName,
  int progressPercent = 0,
}) {
  return LearningRoadmap(
    categoryId: categoryId,
    categoryName: categoryName,
    completedLessons: progressPercent >= 100 ? 1 : 0,
    totalLessons: 5,
    progress: progressPercent.toDouble(),
    currentLessonId: 'lesson-$categoryId-1',
    activeDates: const [],
    units: [
      RoadmapUnit(
        id: 'unit-1',
        title: '$categoryName Unit 1',
        description: 'Unit 1 Description',
        position: 1,
        status: RoadmapUnitStatus.current,
        completedLessons: progressPercent >= 100 ? 1 : 0,
        totalLessons: 1,
        skippable: false,
        lessons: [
          RoadmapLesson(
            id: 'lesson-$categoryId-1',
            title: '$categoryName Intro',
            description: 'Description for $categoryName',
            status: progressPercent > 0
                ? RoadmapLessonStatus.inProgress
                : RoadmapLessonStatus.available,
            difficulty: LessonDifficulty.easy,
            baseXp: 20,
            rewardXp: 20,
            estimatedMinutes: 10,
            exerciseCount: 2,
            progress: progressPercent / 100.0,
            current: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  const mathCategory = LearningCategory(
    id: 'cat-math-uuid',
    name: 'Mathematics',
    slug: 'mathematics',
  );
  const physicsCategory = LearningCategory(
    id: 'cat-physics-uuid',
    name: 'Physics',
    slug: 'physics',
  );
  const chemistryCategory = LearningCategory(
    id: 'cat-chem-uuid',
    name: 'Chemistry',
    slug: 'chemistry',
  );

  group('learningHomeProvider with onboarding preferred subject', () {
    test('prioritizes onboarding preferred category as resume subject on fresh profile', () async {
      SharedPreferences.setMockInitialValues({
        'riksa_onboarding_subject': 'PHYSICS',
        'riksa_onboarding_subject_id': 'cat-physics-uuid',
      });

      final container = ProviderContainer(
        overrides: [
          learningApiProvider.overrideWithValue(
            _FakeLearningHomeApi(const [
              mathCategory,
              physicsCategory,
              chemistryCategory,
            ]),
          ),
          learningRoadmapProvider('cat-math-uuid').overrideWith(
            (ref) async => _fakeRoadmap(
              categoryId: 'cat-math-uuid',
              categoryName: 'Mathematics',
              progressPercent: 0,
            ),
          ),
          learningRoadmapProvider('cat-physics-uuid').overrideWith(
            (ref) async => _fakeRoadmap(
              categoryId: 'cat-physics-uuid',
              categoryName: 'Physics',
              progressPercent: 0,
            ),
          ),
          learningRoadmapProvider('cat-chem-uuid').overrideWith(
            (ref) async => _fakeRoadmap(
              categoryId: 'cat-chem-uuid',
              categoryName: 'Chemistry',
              progressPercent: 0,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final homeData = await container.read(learningHomeProvider.future);

      expect(homeData.resumeSubject, isNotNull);
      expect(homeData.resumeSubject!.category.id, 'cat-physics-uuid');
      expect(homeData.resumeSubject!.subject, StemSubject.physics);

      // Preferred subject is placed first in the subject syllabus list
      expect(homeData.subjects.first.category.id, 'cat-physics-uuid');
    });

    test('prioritizes already started lessons over onboarding preference once learner begins study', () async {
      SharedPreferences.setMockInitialValues({
        'riksa_onboarding_subject': 'PHYSICS',
        'riksa_onboarding_subject_id': 'cat-physics-uuid',
      });

      final container = ProviderContainer(
        overrides: [
          learningApiProvider.overrideWithValue(
            _FakeLearningHomeApi(const [
              mathCategory,
              physicsCategory,
            ]),
          ),
          // Math has progress!
          learningRoadmapProvider('cat-math-uuid').overrideWith(
            (ref) async => _fakeRoadmap(
              categoryId: 'cat-math-uuid',
              categoryName: 'Mathematics',
              progressPercent: 50,
            ),
          ),
          // Physics has no progress
          learningRoadmapProvider('cat-physics-uuid').overrideWith(
            (ref) async => _fakeRoadmap(
              categoryId: 'cat-physics-uuid',
              categoryName: 'Physics',
              progressPercent: 0,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final homeData = await container.read(learningHomeProvider.future);

      // Even though onboarding chose Physics, Math has active progress (50%),
      // so resumeSubject should be Math!
      expect(homeData.resumeSubject, isNotNull);
      expect(homeData.resumeSubject!.category.id, 'cat-math-uuid');
      expect(homeData.resumeSubject!.subject, StemSubject.mathematics);
    });
  });
}
