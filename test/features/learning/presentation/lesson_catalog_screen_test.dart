import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
);

class _CatalogNotifier extends LessonCatalogNotifier {
  @override
  LessonCatalogState build() => const LessonCatalogState(
    lessons: [_lesson],
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
}

void main() {
  testWidgets('lessons precede advanced filters and sheet applies grade', (
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

    expect(find.text("TODAY'S MISSION"), findsOneWidget);
    expect(find.text('Recommended lessons'), findsOneWidget);
    expect(find.text('Derivatives & Tangent Lines'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('lesson-filter-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lesson-filter-sheet')), findsOneWidget);
    expect(find.text('Grade'), findsOneWidget);
    await tester.tap(find.text('Grade 10'));
    await tester.ensureVisible(find.byKey(const ValueKey('apply-filters')));
    await tester.tap(find.byKey(const ValueKey('apply-filters')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-grade-filter')), findsOneWidget);
    expect(
      find.textContaining('Until lessons receive grade tags'),
      findsOneWidget,
    );
    expect(find.text('Derivatives & Tangent Lines'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('learning-streak-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('streak-details-sheet')), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Best streak'), findsOneWidget);
    expect(find.text('Last tracked'), findsOneWidget);
    expect(find.text('Aug 22, 2026'), findsOneWidget);
  });
}
