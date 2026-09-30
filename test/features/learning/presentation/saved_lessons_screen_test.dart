import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/providers/current_user_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/saved_lessons_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:riksa_app/features/learning/providers/saved_lessons_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _savedLesson1 = LessonSummary(
  id: 'lesson-1',
  title: 'Introduction to Calculus',
  description: 'Basics of limits and derivatives',
  difficulty: LessonDifficulty.easy,
  baseXp: 40,
  categoryId: 'math',
  categoryName: 'គណិតវិទ្យា',
  exerciseCount: 5,
  completed: false,
  createdAt: null,
);

const _savedLesson2 = LessonSummary(
  id: 'lesson-2',
  title: 'Newtonian Mechanics',
  description: 'Forces and motion',
  difficulty: LessonDifficulty.medium,
  baseXp: 50,
  categoryId: 'physics',
  categoryName: 'រូបវិទ្យា',
  exerciseCount: 6,
  completed: false,
  createdAt: null,
);

/// A catalog that holds none of the saved lessons, so the home syllabus is
/// the only place they could be found.
class _EmptyCatalogNotifier extends LessonCatalogNotifier {
  @override
  LessonCatalogState build() => const LessonCatalogState();
}

class _TestCatalogNotifier extends LessonCatalogNotifier {
  @override
  LessonCatalogState build() {
    return const LessonCatalogState(
      lessons: [_savedLesson1, _savedLesson2],
      isLoading: false,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'riksa_saved_lesson_ids': ['lesson-1'],
    });
  });

  Widget buildScreen(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: const SavedLessonsScreen(),
      ),
    );
  }

  testWidgets('renders empty state when no lessons are saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        lessonCatalogProvider.overrideWith(_TestCatalogNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container));
    await tester.pumpAndSettle();

    expect(find.text('Keep a good idea for later'), findsOneWidget);
    expect(find.text('Browse lessons'), findsOneWidget);
  });

  testWidgets('renders saved lessons cards and allows removing a bookmark', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        lessonCatalogProvider.overrideWith(_TestCatalogNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    // Initial state restored from preferences
    await tester.pumpWidget(buildScreen(container));
    await tester.pumpAndSettle();

    // lesson-1 should be shown
    expect(find.text('Introduction to Calculus'), findsOneWidget);
    expect(find.textContaining('+40 XP'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved-lesson-card-lesson-1')),
      findsOneWidget,
    );

    // Remove button should be present
    final removeButton = find.byKey(
      const ValueKey('remove-saved-lesson-lesson-1'),
    );
    expect(removeButton, findsOneWidget);

    // Tap remove
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    // Now it should be empty state
    expect(find.text('Keep a good idea for later'), findsOneWidget);
    expect(container.read(savedLessonsProvider).contains('lesson-1'), isFalse);
  });
  testWidgets('a failed load is not mistaken for having no bookmarks', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        lessonCatalogProvider.overrideWith(_EmptyCatalogNotifier.new),
        learningHomeProvider.overrideWith(
          (ref) => Future<LearningHomeData>.error(Exception('offline')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-lessons-load-failed')),
      findsOneWidget,
    );
    expect(find.text('Keep a good idea for later'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(container.read(savedLessonsProvider), contains('lesson-1'));
  });

  testWidgets('bookmarks missing from the syllabus can be cleared', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        lessonCatalogProvider.overrideWith(_EmptyCatalogNotifier.new),
        learningHomeProvider.overrideWith(
          (ref) async => const LearningHomeData(
            subjects: [],
            resumeSubject: null,
            resumeLesson: null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-lessons-unavailable')),
      findsOneWidget,
    );
    await tester.tap(find.text('Clear saved lessons'));
    await tester.pumpAndSettle();

    expect(container.read(savedLessonsProvider), isEmpty);
    expect(find.text('Keep a good idea for later'), findsOneWidget);
  });
}
