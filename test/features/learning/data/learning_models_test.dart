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
}
