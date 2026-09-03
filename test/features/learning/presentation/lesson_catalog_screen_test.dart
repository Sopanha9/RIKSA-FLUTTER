import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_catalog_screen.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _lesson = LessonSummary(
  id: 'lesson-1',
  title: 'Derivatives & Tangent Lines',
  description: 'Learn the power rule and find tangent-line equations.',
  difficulty: LessonDifficulty.easy,
  baseXp: 20,
  categoryId: 'math',
  categoryName: 'Mathematics',
  exerciseCount: 2,
  completed: false,
  createdAt: null,
  durationMinutes: 12,
  progress: .68,
);

const _biologyLesson = LessonSummary(
  id: 'lesson-2',
  title: 'ស្វែងយល់ពីកោសិកា',
  description: 'Explore the structures that keep living cells working.',
  difficulty: LessonDifficulty.easy,
  baseXp: 25,
  categoryId: 'biology',
  categoryName: 'Biology',
  exerciseCount: 4,
  completed: false,
  createdAt: null,
);

const _physicsLesson = LessonSummary(
  id: 'lesson-3',
  title: 'Motion, forces and everyday life',
  description: 'Connect force and motion to familiar examples.',
  difficulty: LessonDifficulty.medium,
  baseXp: 30,
  categoryId: 'physics',
  categoryName: 'Physics',
  exerciseCount: 5,
  completed: false,
  createdAt: null,
);

const _technologyLesson = LessonSummary(
  id: 'lesson-4',
  title: 'Think like a programmer',
  description: 'Break a problem into clear, reusable steps.',
  difficulty: LessonDifficulty.medium,
  baseXp: 35,
  categoryId: 'technology',
  categoryName: 'Computer Science',
  exerciseCount: 6,
  completed: false,
  createdAt: null,
);

class _CatalogNotifier extends LessonCatalogNotifier {
  @override
  LessonCatalogState build() => const LessonCatalogState(
    lessons: [_lesson, _biologyLesson, _physicsLesson, _technologyLesson],
    categories: [LearningCategory(id: 'math', name: 'Mathematics')],
    totalPages: 1,
  );

  @override
  Future<void> applyFilters({
    int? grade,
    String? categoryId,
    LessonDifficulty? difficulty,
  }) async {
    state = state.copyWith(
      selectedGrade: grade,
      clearGrade: grade == null,
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      selectedDifficulty: difficulty,
      clearDifficulty: difficulty == null,
    );
  }

  @override
  Future<void> selectCategory(String? categoryId) async {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }
}

void main() {
  testWidgets('opens non-Math lessons directly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/learn',
      routes: [
        GoRoute(
          path: '/learn',
          builder: (_, _) => const LessonCatalogScreen(),
          routes: [
            GoRoute(
              path: 'roadmap/:categoryId',
              builder: (_, state) => Scaffold(
                body: Text('roadmap-${state.pathParameters['categoryId']}'),
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (_, _) => const Scaffold(body: Text('detail-screen')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonCatalogProvider.overrideWith(_CatalogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => CommunityStreak(
              current: 0,
              highest: 0,
              lastTrackedDate: null,
              activityDates: const [],
            ),
          ),
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

    await tester.tap(find.byKey(const ValueKey('lesson-card-lesson-2')));
    await tester.pumpAndSettle();

    expect(find.text('detail-screen'), findsOneWidget);
  });

  testWidgets('keeps the Learning header below the device top inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonCatalogProvider.overrideWith(_CatalogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => CommunityStreak(
              current: 7,
              highest: 12,
              lastTrackedDate: DateTime(2026, 8, 22),
              activityDates: const [],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 59)),
              child: const LessonCatalogScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Learning')).dy,
      greaterThanOrEqualTo(59),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the stacked library and keeps real filters working', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonCatalogProvider.overrideWith(_CatalogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => CommunityStreak(
              current: 7,
              highest: 12,
              lastTrackedDate: DateTime(2026, 8, 22),
              activityDates: [
                DateTime(2026, 8, 20),
                DateTime(2026, 8, 21),
                DateTime(2026, 8, 22),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const LessonCatalogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-subject-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-card-lesson-1')), findsOneWidget);
    expect(find.text('Continue learning'), findsOneWidget);
    expect(find.text('Derivatives & Tangent Lines'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lesson-progress-lesson-1')),
      findsOneWidget,
    );
    final firstCard = tester.getRect(
      find.byKey(const ValueKey('lesson-card-lesson-1')),
    );
    final secondCard = tester.getRect(
      find.byKey(const ValueKey('lesson-card-lesson-2')),
    );
    expect(secondCard.top - firstCard.bottom, 14);
    final khmerCardTitle = tester.widget<Text>(find.text(_biologyLesson.title));
    expect(khmerCardTitle.style?.fontFamily, RiksaTypography.khmerTitleFamily);

    await tester.tap(find.byKey(const ValueKey('lesson-category-math')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LessonCatalogScreen)),
    );
    expect(container.read(lessonCatalogProvider).selectedCategoryId, 'math');

    await tester.tap(find.byKey(const ValueKey('lesson-category-all')));
    await tester.pumpAndSettle();
    expect(container.read(lessonCatalogProvider).selectedCategoryId, isNull);

    await tester.tap(find.byKey(const ValueKey('lesson-filter-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lesson-filter-sheet')), findsOneWidget);
    expect(find.text('Grade'), findsOneWidget);
    await tester.tap(find.text('Grade 10'));
    await tester.ensureVisible(find.byKey(const ValueKey('apply-filters')));
    await tester.tap(find.byKey(const ValueKey('apply-filters')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-filter-count')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('active-filter-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Derivatives & Tangent Lines'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('learning-streak-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('streak-details-sheet')), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Best streak'), findsOneWidget);
    expect(find.text('Last tracked'), findsOneWidget);
    expect(find.text('Aug 22, 2026'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('streak-details-sheet'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const PageStorageKey('lesson-catalog-scroll')),
      const Offset(0, -1200),
      2200,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lesson-card-lesson-4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
