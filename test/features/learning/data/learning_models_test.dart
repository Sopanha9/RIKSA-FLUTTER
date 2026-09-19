import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';

void main() {
  test('LessonPage parses the current Spring page response', () {
    final page = LessonPage.fromJson({
      'content': [
        {
          'id': 'lesson-1',
          'title': 'Derivatives',
          'description': 'Learn the power rule.',
          'difficulty': 'EASY',
          'baseXp': 20,
          'categoryId': 'math',
          'categoryName': 'Mathematics',
          'exerciseCount': 2,
          'completed': true,
          'createdAt': '2026-08-20T10:00:00Z',
        },
      ],
      'number': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
    });

    expect(page.content, hasLength(1));
    expect(page.content.single.difficulty, LessonDifficulty.easy);
    expect(page.content.single.exerciseCount, 2);
    expect(page.content.single.completed, isTrue);
    expect(page.content.single.grade, isNull);
    expect(page.hasMore, isFalse);
  });

  test('LessonSummary accepts future numeric and labelled grade fields', () {
    final numeric = LessonSummary.fromJson({'grade': 10});
    final labelled = LessonSummary.fromJson({'grade': 'Grade 12'});

    expect(numeric.grade, 10);
    expect(labelled.grade, 12);
  });

  test('LessonSummary distinguishes explicit and legacy content types', () {
    final explicit = LessonSummary.fromJson({
      'title': 'Weekly review',
      'contentType': 'CHALLENGE',
    });
    final legacy = LessonSummary.fromJson({
      'title': 'Mathematics Roadmap Challenge',
    });
    final regular = LessonSummary.fromJson({'title': 'Linear equations'});

    expect(explicit.contentType, LessonContentType.challenge);
    expect(legacy.contentType, LessonContentType.challenge);
    expect(regular.contentType, LessonContentType.lesson);
  });

  test('LearningRoadmap parses nested units, resume state, and reward XP', () {
    final roadmap = LearningRoadmap.fromJson({
      'categoryId': 'math',
      'categoryName': 'Mathematics',
      'completedLessons': 2,
      'totalLessons': 5,
      'progress': 0.4,
      'currentLessonId': 'lesson-3',
      'activeDates': ['2026-08-27'],
      'units': [
        {
          'id': 'foundation',
          'title': 'Foundations',
          'description': 'Basic concepts',
          'position': 1,
          'status': 'CURRENT',
          'completedLessons': 2,
          'totalLessons': 5,
          'skippable': true,
          'lessons': [
            {
              'id': 'lesson-3',
              'title': 'Equations',
              'description': 'Solve equations',
              'difficulty': 'MEDIUM',
              'baseXp': 20,
              'rewardXp': 55,
              'estimatedMinutes': 10,
              'exerciseCount': 2,
              'progress': 0.5,
              'status': 'IN_PROGRESS',
              'current': true,
            },
          ],
        },
      ],
    });

    expect(roadmap.units.single.lessons.single.rewardXp, 55);
    expect(
      roadmap.units.single.lessons.single.status,
      RoadmapLessonStatus.inProgress,
    );
    expect(roadmap.currentLessonId, 'lesson-3');
    expect(roadmap.activeDates.single, DateTime(2026, 8, 27));
  });

  test('LessonDetail restores completed exercise state', () {
    final detail = LessonDetail.fromJson({
      'id': 'lesson-1',
      'title': 'Numbers',
      'exercises': [
        {
          'id': 'exercise-1',
          'question': 'What is 2 + 2?',
          'difficulty': 'EASY',
          'points': 5,
          'sectionIndex': 3,
          'type': 'MULTIPLE_CHOICE',
          'options': ['4', '5'],
          'hint': 'Add carefully.',
          'explanation': 'Two plus two is four.',
          'completed': true,
        },
      ],
    });

    expect(detail.exercises.single.completed, isTrue);
    expect(detail.exercises.single.sectionIndex, 3);
    expect(detail.exercises.single.type, LessonExerciseType.multipleChoice);
    expect(detail.exercises.single.options, ['4', '5']);
    expect(detail.exercises.single.hint, 'Add carefully.');
    expect(detail.exercises.single.explanation, 'Two plus two is four.');
  });

  test('ContinueLearningResponse parses the server progress read model', () {
    final response = ContinueLearningResponse.fromJson({
      'allCompleted': false,
      'lesson': {
        'lessonId': 'lesson-1',
        'lessonTitle': 'Algebraic Expressions',
        'categoryId': 'math',
        'categoryName': 'Mathematics',
        'roadmapState': 'AVAILABLE',
        'totalExerciseCount': 4,
        'attemptedExerciseCount': 3,
        'correctExerciseCount': 2,
        'progressPercentage': 50.0,
        'currentSectionIndex': 3,
        'lastActivityAt': '2026-09-04T06:00:00Z',
        'completed': false,
        'canResume': true,
        'difficulty': 'EASY',
        'baseXp': 60,
        'position': 1,
      },
    });

    expect(response.allCompleted, isFalse);
    expect(response.lesson!.lessonTitle, 'Algebraic Expressions');
    expect(response.lesson!.progress, 0.5);
    expect(response.lesson!.currentSectionIndex, 3);
    expect(response.lesson!.canResume, isTrue);
  });
}
