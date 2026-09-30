import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_design.dart';
import 'package:riksa_app/features/learning/presentation/subject_map.dart';
import 'package:riksa_app/features/learning/presentation/subject_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Physics has no map art yet, so it still draws the stone list.
final _roadmap = LearningRoadmap(
  categoryId: 'math',
  categoryName: 'Physics',
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
        // The buddy on the map idles forever; reduced motion lets it settle.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
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

final _mathRoadmap = LearningRoadmap(
  categoryId: _roadmap.categoryId,
  categoryName: 'Mathematics',
  completedLessons: _roadmap.completedLessons,
  totalLessons: _roadmap.totalLessons,
  progress: _roadmap.progress,
  currentLessonId: _roadmap.currentLessonId,
  activeDates: const [],
  units: _roadmap.units,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Mathematics map', () {
    test('spreads every lesson along the road, top to bottom', () {
      final art = subjectMapArtFor(StemSubject.mathematics)!;
      final layout = SubjectMapLayout.of(art, width: 393, lessons: 14);

      // Start, two middle sections and the goal.
      expect(layout.pieces, hasLength(4));
      expect(layout.pieces.first, art.start);
      expect(layout.pieces.last, art.goal);
      expect(layout.nodes, hasLength(14));
      for (var i = 1; i < layout.nodes.length; i++) {
        expect(layout.nodes[i].dy, greaterThan(layout.nodes[i - 1].dy));
      }
      for (final node in layout.nodes) {
        expect(node.dx, inInclusiveRange(0, 393));
        expect(node.dy, inInclusiveRange(0, layout.height));
      }
    });

    test('a short subject needs only the start and the goal', () {
      final art = subjectMapArtFor(StemSubject.mathematics)!;
      final layout = SubjectMapLayout.of(art, width: 393, lessons: 4);
      expect(layout.pieces, [art.start, art.goal]);
      expect(layout.nodes, hasLength(4));
    });

    testWidgets('puts each lesson on the map and opens the open ones', (
      tester,
    ) async {
      final router = _router();
      addTearDown(router.dispose);
      await _pump(tester, roadmap: () async => _mathRoadmap, router: router);

      for (final id in ['one', 'two', 'three', 'four']) {
        expect(find.byKey(ValueKey('map-lesson-$id')), findsOneWidget);
      }
      // One lesson is done, so the current stop says to carry on.
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.byKey(const ValueKey('roadmap-unit-u1')), findsNothing);

      final locked = find.byKey(const ValueKey('map-lesson-four'));
      await tester.ensureVisible(locked);
      await tester.pumpAndSettle();
      await tester.tap(locked);
      await tester.pump();
      expect(
        find.text('Finish the lessons before this one to unlock it'),
        findsOneWidget,
      );
      expect(find.text('lesson-four'), findsNothing);

      final open = find.byKey(const ValueKey('map-lesson-three'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.text('lesson-three'), findsOneWidget);
    });
  });

  testWidgets('every subject walks the same map, not just Mathematics', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(tester, roadmap: () async => _roadmap, router: router);

    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('1 of 4 lessons · Unit 2 of 3'), findsOneWidget);
    for (final id in ['one', 'two', 'three', 'four']) {
      expect(find.byKey(ValueKey('map-lesson-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('roadmap-unit-u1')), findsNothing);

    final open = find.byKey(const ValueKey('map-lesson-three'));
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
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
