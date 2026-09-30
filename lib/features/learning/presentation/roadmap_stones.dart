import '../data/learning_models.dart';
import 'learning_design.dart';

/// One step on a subject's path.
///
/// A stone is either a syllabus unit, which carries its own [lessons], or a
/// single lesson sitting inside one. `GET /lessons/roadmap` returns the subject
/// grouped into ordered units, so the spine draws unit stones and opens the
/// current one to reveal the lessons inside it.
class RoadmapStone {
  const RoadmapStone({
    required this.id,
    required this.title,
    required this.status,
    required this.index,
    this.lesson,
    this.lessons = const [],
    this.completedLessons = 0,
    this.totalLessons = 0,
  });

  final String id;
  final String title;
  final LearningStatus status;

  /// Position on the path, starting at 1. Shown inside the node.
  final int index;

  /// Set when this stone is a lesson in its own right.
  final LessonSummary? lesson;

  /// Set when this stone is a unit. Empty for a lesson stone.
  final List<RoadmapStone> lessons;

  final int completedLessons;
  final int totalLessons;

  bool get isUnit => lessons.isNotEmpty;

  /// Locked stones are the only ones a learner cannot open.
  bool get isOpenable => status != LearningStatus.locked;

  /// The lesson a unit stone should offer as its primary action: the one the
  /// API flagged as current, otherwise the first one still open.
  RoadmapStone? get resumableLesson {
    if (!isUnit) return status == LearningStatus.current ? this : null;
    return lessons
            .where((lesson) => lesson.status == LearningStatus.current)
            .firstOrNull ??
        lessons.where((lesson) => lesson.status == LearningStatus.todo).firstOrNull;
  }
}

/// Turns the API roadmap into the path the screen draws.
///
/// Unit and lesson state both come from the server rather than being inferred
/// here: it owns the gating rules, including units a learner chose to skip.
/// The one thing this adds is a running lesson number across the whole subject,
/// because a learner thinks in "lesson 6 of 13", not "lesson 2 of unit 3".
List<RoadmapStone> buildRoadmapStones(LearningRoadmap roadmap) {
  final units = [...roadmap.units]
    ..sort((a, b) => a.position.compareTo(b.position));

  var lessonNumber = 0;
  return [
    for (final (index, unit) in units.indexed)
      RoadmapStone(
        id: unit.id,
        title: unit.title,
        index: index + 1,
        status: _unitStatus(unit.status),
        completedLessons: unit.completedLessons,
        totalLessons: unit.totalLessons,
        lessons: [
          for (final lesson in unit.lessons)
            RoadmapStone(
              id: lesson.id,
              title: lesson.title,
              index: ++lessonNumber,
              // The server flags the lesson to resume with `current`, and it
              // does so even while that lesson is still AVAILABLE rather than
              // IN_PROGRESS. Reading only the status would leave the whole
              // spine with nothing marked as the place to carry on from.
              status:
                  lesson.current || lesson.id == roadmap.currentLessonId
                  ? LearningStatus.current
                  : _lessonStatus(lesson.status),
              lesson: lesson.toSummary(
                categoryId: roadmap.categoryId,
                categoryName: roadmap.categoryName,
                position: lessonNumber,
              ),
            ),
        ],
      ),
  ];
}

LearningStatus _unitStatus(RoadmapUnitStatus status) => switch (status) {
  RoadmapUnitStatus.completed => LearningStatus.done,
  RoadmapUnitStatus.current => LearningStatus.current,
  RoadmapUnitStatus.locked => LearningStatus.locked,
  // A skipped unit stays reachable: the learner passed it over, they were not
  // gated out of it.
  RoadmapUnitStatus.skipped => LearningStatus.todo,
};

LearningStatus _lessonStatus(RoadmapLessonStatus status) => switch (status) {
  RoadmapLessonStatus.completed => LearningStatus.done,
  RoadmapLessonStatus.inProgress => LearningStatus.current,
  RoadmapLessonStatus.locked => LearningStatus.locked,
  RoadmapLessonStatus.available => LearningStatus.todo,
  RoadmapLessonStatus.skipped => LearningStatus.todo,
};

/// Aggregate counts for the roadmap header, taken from the server's own totals
/// rather than recounted, so the header cannot disagree with the backend.
class RoadmapSummary {
  const RoadmapSummary({
    required this.completed,
    required this.total,
    required this.currentUnit,
    required this.totalUnits,
  });

  factory RoadmapSummary.of(
    LearningRoadmap roadmap,
    List<RoadmapStone> stones,
  ) {
    final current = stones
        .where((stone) => stone.status == LearningStatus.current)
        .firstOrNull;
    return RoadmapSummary(
      completed: roadmap.completedLessons,
      total: roadmap.totalLessons,
      currentUnit: current?.index ?? stones.length,
      totalUnits: stones.length,
    );
  }

  final int completed;
  final int total;

  /// 1-based position of the current unit, for "Unit 4 of 8".
  final int currentUnit;
  final int totalUnits;

  double get fraction => total == 0 ? 0 : completed / total;

  bool get isFinished => total > 0 && completed == total;
}
