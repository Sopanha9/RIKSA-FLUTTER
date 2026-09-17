import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/subject_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

RoadmapLesson _rl(
  String id,
  String title, {
  RoadmapLessonStatus status = RoadmapLessonStatus.available,
  bool current = false,
  int minutes = 8,
}) => RoadmapLesson(
  id: id,
  title: title,
  description: '',
  difficulty: LessonDifficulty.medium,
  baseXp: 25,
  rewardXp: 25,
  estimatedMinutes: minutes,
  exerciseCount: 0,
  progress: 0,
  status: status,
  current: current,
);

RoadmapUnit _ru(
  String id,
  String title,
  int position,
  RoadmapUnitStatus status,
  List<RoadmapLesson> lessons, {
  int completed = 0,
}) => RoadmapUnit(
  id: id,
  title: title,
  description: '',
  position: position,
  status: status,
  completedLessons: completed,
  totalLessons: lessons.length,
  skippable: false,
  lessons: lessons,
);

final _roadmap = LearningRoadmap(
  categoryId: 'math',
  categoryName: 'Mathematics',
  completedLessons: 1,
  totalLessons: 4,
  progress: .25,
  currentLessonId: 'two',
  activeDates: const [],
  units: [
    _ru('u1', 'Foundations', 1, RoadmapUnitStatus.completed, [
      _rl('one', 'Antiderivatives', status: RoadmapLessonStatus.completed),
    ], completed: 1),
    _ru('u2', 'Integrals', 2, RoadmapUnitStatus.current, [
      _rl('two', 'Definite integrals and area', current: true),
      _rl('three', 'Volumes of revolution', minutes: 11),
    ]),
    _ru('u3', 'Differential equations', 3, RoadmapUnitStatus.locked, [
      _rl('four', 'Improper integrals', status: RoadmapLessonStatus.locked),
    ]),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<LearningRoadmap> Function() roadmap,
  required GoRouter router,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learningRoadmapProvider('math').overrideWith((ref) => roadmap()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const LearningRoadmapScreen(categoryId: 'math'),
    ),
    GoRoute(
      path: '/learn/:id',
      builder: (_, state) =>
          Scaffold(body: Text('lesson-${state.pathParameters['id']}')),
    ),
  ],
);

void main() {
  testWidgets('draws the whole path, its position and its destination', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(tester, roadmap: () async => _roadmap, router: router);

    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('1 of 4 lessons · Unit 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap-progress-ring')), findsOneWidget);

    // Units are the stones; only the current one opens to show its lessons.
    for (final id in ['u1', 'u2', 'u3']) {
      expect(find.byKey(ValueKey('roadmap-unit-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('roadmap-lesson-two')), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap-lesson-three')), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap-lesson-one')), findsNothing);

    // State is legible without reading a lesson title.
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('0 of 2 done'), findsOneWidget);
    expect(find.text('Opens after Unit 2'), findsOneWidget);

    // The path ends at the reason it exists.
    expect(find.byKey(const ValueKey('roadmap-goal')), findsOneWidget);
    expect(find.text('Ready for Bac II'), findsOneWidget);
  });

  testWidgets('only the current stone carries a primary action', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(tester, roadmap: () async => _roadmap, router: router);

    expect(find.byKey(const ValueKey('roadmap-continue-u2')), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap-continue-u1')), findsNothing);
    expect(find.byKey(const ValueKey('roadmap-continue-u3')), findsNothing);
  });

  testWidgets('opens an available lesson and refuses a locked one', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(tester, roadmap: () async => _roadmap, router: router);

    // A locked unit does not open, so its lessons are not even reachable.
    await tester.tap(find.byKey(const ValueKey('roadmap-unit-u3')));
    await tester.pumpAndSettle();
    expect(find.text('lesson-four'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('roadmap-lesson-three')));
    await tester.pumpAndSettle();
    expect(find.text('lesson-three'), findsOneWidget);
  });

  testWidgets('offers a retry when the roadmap fails', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      roadmap: () async => throw StateError('offline'),
      router: router,
    );

    expect(find.text('We couldn’t load this roadmap'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // A failing retry must never leave the learner without a way out.
    expect(find.byKey(const ValueKey('learning-status-back')), findsOneWidget);
    expect(find.text('Back to subjects'), findsOneWidget);
  });

  testWidgets('explains an empty subject instead of drawing an empty path', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      roadmap: () async => const LearningRoadmap(
        categoryId: 'math',
        categoryName: 'Mathematics',
        completedLessons: 0,
        totalLessons: 0,
        progress: 0,
        currentLessonId: null,
        activeDates: [],
        units: [],
      ),
      router: router,
    );

    expect(find.text('This subject has no lessons yet'), findsWidgets);
    expect(find.byKey(const ValueKey('roadmap-goal')), findsNothing);
    expect(find.byKey(const ValueKey('roadmap-progress-ring')), findsNothing);
  });
}
