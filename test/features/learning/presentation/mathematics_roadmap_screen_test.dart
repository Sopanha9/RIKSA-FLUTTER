import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/mathematics_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';

const _summary = LessonSummary(
  id: 'lesson-1',
  title: 'Numbers',
  description: 'Number systems',
  difficulty: LessonDifficulty.easy,
  baseXp: 15,
  categoryId: 'math',
  categoryName: 'Mathematics',
  exerciseCount: 2,
  completed: false,
  createdAt: null,
);

const _foundationLessons = [
  RoadmapLesson(
    id: 'lesson-1',
    title: 'ប្រព័ន្ធចំនួន និងប្រមាណវិធី',
    description: 'Work with numbers.',
    difficulty: LessonDifficulty.easy,
    baseXp: 15,
    rewardXp: 33,
    estimatedMinutes: 8,
    exerciseCount: 2,
    progress: .5,
    status: RoadmapLessonStatus.inProgress,
    current: true,
  ),
  RoadmapLesson(
    id: 'lesson-2',
    title: 'Algebraic Expressions',
    description: 'Simplify expressions.',
    difficulty: LessonDifficulty.easy,
    baseXp: 20,
    rewardXp: 40,
    estimatedMinutes: 10,
    exerciseCount: 2,
    progress: 0,
    status: RoadmapLessonStatus.locked,
    current: false,
  ),
  RoadmapLesson(
    id: 'lesson-3',
    title: 'Equations & Inequalities',
    description: 'Solve equations.',
    difficulty: LessonDifficulty.easy,
    baseXp: 25,
    rewardXp: 47,
    estimatedMinutes: 12,
    exerciseCount: 2,
    progress: 0,
    status: RoadmapLessonStatus.locked,
    current: false,
  ),
  RoadmapLesson(
    id: 'lesson-4',
    title: 'The Coordinate Plane',
    description: 'Plot coordinates.',
    difficulty: LessonDifficulty.easy,
    baseXp: 20,
    rewardXp: 40,
    estimatedMinutes: 10,
    exerciseCount: 2,
    progress: 0,
    status: RoadmapLessonStatus.locked,
    current: false,
  ),
  RoadmapLesson(
    id: 'lesson-5',
    title: 'Exponents & Radicals',
    description: 'Use exponent rules.',
    difficulty: LessonDifficulty.medium,
    baseXp: 30,
    rewardXp: 78,
    estimatedMinutes: 14,
    exerciseCount: 2,
    progress: 0,
    status: RoadmapLessonStatus.locked,
    current: false,
  ),
];

const _roadmap = LearningRoadmap(
  categoryId: 'math',
  categoryName: 'Mathematics',
  completedLessons: 0,
  totalLessons: 6,
  progress: 0,
  currentLessonId: 'lesson-1',
  activeDates: [],
  units: [
    RoadmapUnit(
      id: 'foundation',
      title: 'មូលដ្ឋានគ្រឹះ',
      description: 'Basic concepts and numbers',
      position: 1,
      status: RoadmapUnitStatus.current,
      completedLessons: 0,
      totalLessons: 5,
      skippable: true,
      lessons: _foundationLessons,
    ),
    RoadmapUnit(
      id: 'functions',
      title: 'Functions & Graphs',
      description: 'Understand functions and graphs',
      position: 2,
      status: RoadmapUnitStatus.locked,
      completedLessons: 0,
      totalLessons: 1,
      skippable: false,
      lessons: [],
    ),
  ],
);

void main() {
  testWidgets(
    'renders a backend roadmap with five expandable foundation lessons',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRoadmapProvider(
              'math',
            ).overrideWith((ref) async => _roadmap),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LearningRoadmapScreen(
              categoryId: 'math',
              currentLesson: _summary,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('0 of 6 lessons completed'), findsOneWidget);
      expect(find.text('មូលដ្ឋានគ្រឹះ'), findsOneWidget);
      expect(find.text('ប្រព័ន្ធចំនួន និងប្រមាណវិធី'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('មូលដ្ឋានគ្រឹះ')).style?.fontFamily,
        RiksaTypography.khmerTitleFamily,
      );
      expect(
        tester
            .widget<Text>(find.text('ប្រព័ន្ធចំនួន និងប្រមាណវិធី'))
            .style
            ?.fontFamily,
        RiksaTypography.khmerTitleFamily,
      );
      expect(find.text('Exponents & Radicals'), findsOneWidget);
      expect(find.text('+33 XP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('skip-roadmap-unit-foundation')),
        findsOneWidget,
      );

      await tester.fling(
        find.byKey(const PageStorageKey('mathematics-roadmap-scroll')),
        const Offset(0, -700),
        1600,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('skip-roadmap-unit-foundation')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skip មូលដ្ឋានគ្រឹះ?'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    },
  );

  testWidgets('uses dark semantic surfaces throughout the roadmap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRoadmapProvider('math').overrideWith((ref) async => _roadmap),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const LearningRoadmapScreen(
            categoryId: 'math',
            currentLesson: _summary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final unitCard = tester.widget<Material>(
      find.byKey(const ValueKey('roadmap-unit-foundation')),
    );

    expect(scaffold.backgroundColor, RiksaPalette.dark.canvas);
    expect(unitCard.color!.computeLuminance(), lessThan(.2));
    expect(tester.takeException(), isNull);
  });
}
