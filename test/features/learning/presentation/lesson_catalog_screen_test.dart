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
  Future<void> selectGrade(int? grade) async {
    state = state.copyWith(selectedGrade: grade, clearGrade: grade == null);
  }
}

void main() {
  testWidgets('grade pills update selection and explain ungraded data', (
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
            (ref) async => const CommunityStreak(current: 7, highest: 12),
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

    expect(find.text('Grade'), findsOneWidget);
    expect(find.byKey(const Key('grade-filter-10')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('grade-filter-all')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grade-filter-10')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Until lessons receive grade tags'),
      findsOneWidget,
    );
    expect(find.text('Derivatives & Tangent Lines'), findsOneWidget);
  });
}
