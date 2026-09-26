import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_models.dart';
import '../presentation/learning_design.dart';
import 'learning_roadmap_provider.dart';
import 'lesson_catalog_provider.dart';

/// One learning subject and the learner's position inside it.
///
/// Built from `/lessons/roadmap`, which returns the subject's lessons already
/// ordered and carrying per-lesson state. That is the only endpoint today that
/// knows both the size of a syllabus and how far into it the learner is, so it
/// backs both this summary and the roadmap screen. Riverpod caches the call, so
/// opening a subject from the home screen does not refetch.
class SubjectProgress {
  const SubjectProgress({
    required this.category,
    required this.lessons,
    this.completed = 0,
    this.total = 0,
    this.currentLessonId,
    this.unavailable = false,
  });

  /// Flattens the API roadmap, which arrives grouped into ordered units, into
  /// the running lesson list the home screen needs. Counts come from the
  /// server's own totals rather than being recounted here, so the home screen
  /// and the roadmap screen cannot disagree.
  factory SubjectProgress.fromRoadmap(
    LearningCategory category,
    LearningRoadmap roadmap,
  ) {
    final units = [...roadmap.units]
      ..sort((a, b) => a.position.compareTo(b.position));
    var position = 0;
    return SubjectProgress(
      category: category,
      completed: roadmap.completedLessons,
      total: roadmap.totalLessons,
      currentLessonId: roadmap.currentLessonId,
      lessons: [
        for (final unit in units)
          for (final lesson in unit.lessons)
            lesson.toSummary(
              categoryId: roadmap.categoryId.isEmpty
                  ? category.id
                  : roadmap.categoryId,
              categoryName: roadmap.categoryName.isEmpty
                  ? category.name
                  : roadmap.categoryName,
              position: ++position,
            ),
      ],
    );
  }

  final LearningCategory category;

  /// Every lesson in the subject, in syllabus order. Empty when [unavailable].
  final List<LessonSummary> lessons;

  final int completed;
  final int total;

  /// The lesson the server considers current, if any.
  final String? currentLessonId;

  /// True when this subject's roadmap failed to load. The subject still appears
  /// so the learner can open it and retry, but its counts are not shown.
  final bool unavailable;

  StemSubject get subject => stemSubjectFor(category.name);

  double get fraction => total == 0 ? 0 : completed / total;

  bool get isFinished => total > 0 && completed == total;

  /// The lesson this subject would open on: the one the server flagged as
  /// current, otherwise the first that is neither finished nor locked.
  LessonSummary? get resumable {
    final open = lessons
        .where(
          (lesson) =>
              !lesson.completed &&
              lesson.state != LessonProgressState.completed &&
              lesson.state != LessonProgressState.locked,
        )
        .toList(growable: false);
    if (open.isEmpty) return null;
    return open.where((lesson) => lesson.id == currentLessonId).firstOrNull ??
        open.first;
  }
}

/// Everything the learning home screen renders.
class LearningHomeData {
  const LearningHomeData({
    required this.subjects,
    required this.resumeSubject,
    required this.resumeLesson,
    this.examDate,
  });

  final List<SubjectProgress> subjects;

  /// The single subject and lesson the home screen offers to resume. Null once
  /// every subject is finished, or before any subject has an open lesson.
  final SubjectProgress? resumeSubject;
  final LessonSummary? resumeLesson;

  /// The Bac II date. Null until the learning API exposes an exam calendar;
  /// the destination bar renders without a countdown while that is the case.
  final DateTime? examDate;

  int get totalLessons =>
      subjects.fold(0, (sum, subject) => sum + subject.total);

  int get completedLessons =>
      subjects.fold(0, (sum, subject) => sum + subject.completed);

  double get fraction =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  bool get hasCounts => totalLessons > 0;
}

/// Loads every supported subject and its roadmap in parallel.
///
/// A single subject failing does not fail the screen: that subject is kept as
/// [SubjectProgress.unavailable] so the learner can still open and retry it.
/// The categories call failing, or every roadmap failing, does surface an
/// error, because at that point there is nothing truthful left to show.
final learningHomeProvider = FutureProvider.autoDispose<LearningHomeData>((
  ref,
) async {
  final api = ref.watch(learningApiProvider);
  final categories = (await api.categories())
      .where((category) => isLearningCategory(category.name))
      .toList(growable: false);

  if (categories.isEmpty) {
    return const LearningHomeData(
      subjects: [],
      resumeSubject: null,
      resumeLesson: null,
    );
  }

  final subjects = await Future.wait(
    categories.map((category) async {
      try {
        final roadmap = await ref.read(
          learningRoadmapProvider(category.id).future,
        );
        return SubjectProgress.fromRoadmap(category, roadmap);
      } catch (_) {
        return SubjectProgress(
          category: category,
          lessons: const [],
          unavailable: true,
        );
      }
    }),
  );

  if (subjects.every((subject) => subject.unavailable)) {
    throw StateError('No subject roadmap could be loaded');
  }

  final resumeSubject = _pickResumeSubject(subjects);
  return LearningHomeData(
    subjects: subjects,
    resumeSubject: resumeSubject,
    resumeLesson: resumeSubject?.resumable,
  );
});

/// Prefers a subject the learner has already opened a lesson in, so "continue"
/// means continue. Falls back to the subject furthest along that is not yet
/// finished, which is the one they are most likely working through.
SubjectProgress? _pickResumeSubject(List<SubjectProgress> subjects) {
  final open = subjects
      .where((subject) => subject.resumable != null)
      .toList(growable: false);
  if (open.isEmpty) return null;

  final started = open
      .where((subject) => (subject.resumable!.progress ?? 0) > 0)
      .toList(growable: false);
  final pool = started.isNotEmpty ? started : open;

  return pool.reduce((a, b) {
    if (a.isFinished != b.isFinished) return a.isFinished ? b : a;
    return a.fraction >= b.fraction ? a : b;
  });
}
