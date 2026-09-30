import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_design.dart';
import 'package:riksa_app/features/learning/presentation/roadmap_stones.dart';

RoadmapLesson _lesson(
  String id, {
  RoadmapLessonStatus status = RoadmapLessonStatus.available,
  bool current = false,
}) => RoadmapLesson(
  id: id,
  title: 'Lesson $id',
  description: '',
  difficulty: LessonDifficulty.easy,
  baseXp: 25,
  rewardXp: 25,
  estimatedMinutes: 8,
  exerciseCount: 0,
  progress: 0,
  status: status,
  current: current,
);

RoadmapUnit _unit(
  String id,
  int position,
  RoadmapUnitStatus status,
  List<RoadmapLesson> lessons, {
  int? completed,
}) => RoadmapUnit(
  id: id,
  title: 'Unit $position',
  description: '',
  position: position,
  status: status,
  completedLessons: completed ?? 0,
  totalLessons: lessons.length,
  skippable: false,
  lessons: lessons,
);

LearningRoadmap _roadmap(
  List<RoadmapUnit> units, {
  int completed = 0,
  int total = 0,
  String? currentLessonId,
}) => LearningRoadmap(
  categoryId: 'math',
  categoryName: 'Mathematics',
  completedLessons: completed,
  totalLessons: total,
  progress: total == 0 ? 0 : completed / total,
  currentLessonId: currentLessonId,
  activeDates: const [],
  units: units,
);

void main() {
  group('buildRoadmapStones', () {
    test('makes one stone per unit and nests that unit\'s lessons', () {
      final stones = buildRoadmapStones(
        _roadmap(
          [
            _unit('u1', 1, RoadmapUnitStatus.completed, [
              _lesson('a', status: RoadmapLessonStatus.completed),
            ], completed: 1),
            _unit('u2', 2, RoadmapUnitStatus.current, [
              _lesson('b', current: true),
              _lesson('c', status: RoadmapLessonStatus.locked),
            ]),
          ],
          completed: 1,
          total: 3,
        ),
      );

      expect(stones.length, 2);
      expect(stones[0].isUnit, isTrue);
      expect(stones[0].status, LearningStatus.done);
      expect(stones[1].status, LearningStatus.current);
      expect(stones[1].lessons.map((l) => l.id), ['b', 'c']);
      expect(stones[1].lessons[1].status, LearningStatus.locked);
    });

    test('orders units by position regardless of API order', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u3', 3, RoadmapUnitStatus.locked, [_lesson('c')]),
          _unit('u1', 1, RoadmapUnitStatus.current, [_lesson('a')]),
          _unit('u2', 2, RoadmapUnitStatus.locked, [_lesson('b')]),
        ]),
      );

      expect(stones.map((s) => s.id), ['u1', 'u2', 'u3']);
      expect(stones.map((s) => s.index), [1, 2, 3]);
    });

    test('numbers lessons across the whole subject, not per unit', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.completed, [
            _lesson('a'),
            _lesson('b'),
          ]),
          _unit('u2', 2, RoadmapUnitStatus.current, [_lesson('c')]),
        ]),
      );

      expect(stones[0].lessons.map((l) => l.index), [1, 2]);
      expect(stones[1].lessons.single.index, 3);
      expect(stones[1].lessons.single.lesson!.position, 3);
    });

    test('carries the lock across to the summary so it cannot be opened', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.current, [
            _lesson('a', status: RoadmapLessonStatus.locked),
          ]),
        ]),
      );

      expect(
        stones.single.lessons.single.lesson!.state,
        LessonProgressState.locked,
      );
    });

    test('treats a skipped unit as reachable, not locked', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.skipped, [_lesson('a')]),
        ]),
      );

      expect(stones.single.status, LearningStatus.todo);
      expect(stones.single.isOpenable, isTrue);
    });

    test(
      'marks the lesson the server flagged as current, even if AVAILABLE',
      () {
        final stones = buildRoadmapStones(
          _roadmap([
            _unit('u1', 1, RoadmapUnitStatus.current, [
              _lesson('a', status: RoadmapLessonStatus.completed),
              // The seeded backend sends the resume target as AVAILABLE with
              // current: true, never as IN_PROGRESS.
              _lesson('b', current: true),
              _lesson('c', status: RoadmapLessonStatus.locked),
            ]),
          ]),
        );

        expect(stones.single.lessons[1].status, LearningStatus.current);
        expect(stones.single.resumableLesson!.id, 'b');
      },
    );

    test('honours currentLessonId when no lesson carries the flag', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.current, [
            _lesson('a'),
            _lesson('b'),
          ]),
        ], currentLessonId: 'b'),
      );

      expect(stones.single.lessons[1].status, LearningStatus.current);
      expect(stones.single.resumableLesson!.id, 'b');
    });

    test('resumes the lesson the unit is currently on', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.current, [
            _lesson('a', status: RoadmapLessonStatus.completed),
            _lesson('b', status: RoadmapLessonStatus.inProgress),
            _lesson('c'),
          ]),
        ]),
      );

      expect(stones.single.resumableLesson!.id, 'b');
    });

    test('falls back to the first open lesson when none is in progress', () {
      final stones = buildRoadmapStones(
        _roadmap([
          _unit('u1', 1, RoadmapUnitStatus.current, [
            _lesson('a', status: RoadmapLessonStatus.completed),
            _lesson('b'),
          ]),
        ]),
      );

      expect(stones.single.resumableLesson!.id, 'b');
    });
  });

  group('RoadmapSummary', () {
    test('reports the server totals, not a local recount', () {
      final roadmap = _roadmap(
        [
          _unit('u1', 1, RoadmapUnitStatus.completed, [
            _lesson('a'),
          ], completed: 1),
          _unit('u2', 2, RoadmapUnitStatus.current, [_lesson('b')]),
        ],
        completed: 2,
        total: 13,
      );
      final summary = RoadmapSummary.of(roadmap, buildRoadmapStones(roadmap));

      expect(summary.completed, 2);
      expect(summary.total, 13);
      expect(summary.currentUnit, 2);
      expect(summary.totalUnits, 2);
      expect(summary.isFinished, isFalse);
    });

    test('does not divide by zero on an empty subject', () {
      final roadmap = _roadmap(const []);
      final summary = RoadmapSummary.of(roadmap, buildRoadmapStones(roadmap));
      expect(summary.fraction, 0);
      expect(summary.isFinished, isFalse);
    });
  });
}
