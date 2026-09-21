import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_experience_screen.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JourneyApi implements LearningApi {
  final submitted = <String>[];
  final reflections = <String>[];
  bool failCompletion = false;
  @override
  Future<LessonDetail> lesson(String id) async => const LessonDetail(
    id: 'force',
    title: 'Forces and motion',
    categoryId: 'physics',
    categoryName: 'Physics',
    description:
        'Keep units consistent.\n\n## Force\n\nForce is mass times acceleration.',
    difficulty: LessonDifficulty.easy,
    baseXp: 20,
    reflectionPrompt: '',
    exercises: [
      LessonExercise(
        id: 'force-1',
        question: 'Find the force for 2 kg at 3 m/s².',
        difficulty: LessonDifficulty.easy,
        points: 10,
        completed: false,
        type: LessonExerciseType.multipleChoice,
        options: ['5 N', '6 N'],
      ),
    ],
  );
  @override
  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) async {
    submitted.add(answer);
    return LessonAnswerResult(
      exerciseId: exerciseId,
      correct: answer == '6 N',
      points: 10,
      message: answer == '6 N' ? 'Correct.' : 'Try again.',
      explanation: 'Multiply 2 kg by 3 m/s² to get 6 N.',
    );
  }

  @override
  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required String reflectionText,
  }) async {
    reflections.add(reflectionText);
    if (failCompletion) throw Exception('offline');
    return const LessonCompletionResult(xpEarned: 20);
  }

  @override
  Future<LessonPage> listLessons({
    String? categoryId,
    LessonDifficulty? difficulty,
    int? grade,
    int page = 0,
    int size = 20,
  }) async => const LessonPage(
    content: [],
    page: 0,
    totalPages: 0,
    totalElements: 0,
    size: 20,
  );
  @override
  Future<List<LearningCategory>> categories() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget journeyApp(
  JourneyApi api, {
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
}) {
  final router = GoRouter(
    initialLocation: '/learn/force',
    routes: [
      GoRoute(
        path: '/learn/force',
        builder: (_, _) => const LessonExperienceScreen(lessonId: 'force'),
      ),
      GoRoute(
        path: '/learn/completion',
        builder: (_, state) => Scaffold(
          body: Text('Saved: ${(state.extra as Map)['reflection']}'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [learningApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: child!,
      ),
    ),
  );
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.pumpAndSettle();
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'riksa_learning_sound_enabled': false,
    }),
  );

  testWidgets(
    'written work, feedback, reflection and retry survive the full lesson journey',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = JourneyApi();
      await tester.pumpWidget(journeyApp(api));
      await tester.pumpAndSettle();
      expect(find.textContaining('Keep units consistent.'), findsWidgets);
      await tapKey(tester, 'start-section-1');
      expect(find.byKey(const ValueKey('lesson-option-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-option-1')), findsOneWidget);

      await tapKey(tester, 'toggle-working-force-1');
      await tester.enterText(
        find.byKey(const ValueKey('lesson-working-force-1')),
        '2 × 3 = 6 N',
      );
      await tapKey(tester, 'lesson-option-0');
      await tapKey(tester, 'check-answer');
      expect(find.text('Try again.'), findsOneWidget);
      await tapKey(tester, 'lesson-option-1');
      await tapKey(tester, 'check-answer');
      expect(find.text('Correct.'), findsOneWidget);
      expect(
        find.textContaining('Multiply 2 kg by 3 m/s² to get 6 N.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lesson-reflection')), findsNothing);
      await tapKey(tester, 'continue-after-answer');
      await tapKey(tester, 'complete-lesson');
      expect(api.reflections, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('lesson-reflection')),
        'Force grows with mass at the same acceleration.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'lesson-reflection-review');
      api.failCompletion = true;
      await tapKey(tester, 'complete-lesson');
      expect(
        find.text('Force grows with mass at the same acceleration.'),
        findsOneWidget,
      );
      api.failCompletion = false;
      await tapKey(tester, 'complete-lesson');
      expect(
        find.text('Saved: Force grows with mass at the same acceleration.'),
        findsOneWidget,
      );
      expect(api.submitted, ['5 N', '6 N']);
      expect(api.reflections.last, contains('[I want to revisit it]'));
      expect(api.reflections.last, contains('2 × 3 = 6 N'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Khmer reading and written response fit 360dp at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        journeyApp(
          JourneyApi(),
          locale: const Locale('km'),
          scaler: TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'start-section-1');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'toggle-working-force-1');
      await tester.enterText(
        find.byKey(const ValueKey('lesson-working-force-1')),
        '2 × 3 = 6 N',
      );
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'lesson-option-1');
      await tapKey(tester, 'check-answer');
      await tapKey(tester, 'continue-after-answer');
      await tester.enterText(
        find.byKey(const ValueKey('lesson-reflection')),
        'កម្លាំងអាស្រ័យលើម៉ាស និងសំទុះ។',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'lesson-reflection-review');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders multi-section STEM lesson with LaTeX formulas and maps exercises to sections',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = StemMultiSectionApi();
      final router = GoRouter(
        initialLocation: '/learn/stem-multi',
        routes: [
          GoRoute(
            path: '/learn/stem-multi',
            builder: (_, _) => const LessonExperienceScreen(lessonId: 'stem-multi'),
          ),
          GoRoute(
            path: '/learn/completion',
            builder: (_, state) => Scaffold(
              body: Text('Completed: ${(state.extra as Map)['xpEarned']} XP'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [learningApiProvider.overrideWithValue(api)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light,
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

      // Verify Section 1 reading is rendered with heading
      expect(find.textContaining('Introduction to Force'), findsWidgets);
      await tapKey(tester, 'start-section-1');

      // Section 1 has Exercise 1 (force)
      expect(find.byKey(const ValueKey('lesson-exercise-stem-ex-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-exercise-stem-ex-2')), findsNothing);

      // Tap formula option ($6\text{ N}$) and check answer
      await tapKey(tester, 'lesson-option-1');
      await tapKey(tester, 'check-answer');
      expect(find.text('Correct!'), findsOneWidget);

      // Complete Section 1 and proceed to Section 2
      await tapKey(tester, 'continue-after-answer');
      await tapKey(tester, 'continue-to-section-2');
      expect(find.textContaining('Momentum and Impulse'), findsWidgets);
      await tapKey(tester, 'start-section-2');

      // Section 2 has Exercise 2 (momentum)
      expect(find.byKey(const ValueKey('lesson-exercise-stem-ex-2')), findsOneWidget);

      // Tap formula option ($20\text{ kg}\cdot\text{m/s}$) and check answer
      await tapKey(tester, 'lesson-option-0');
      await tapKey(tester, 'check-answer');
      expect(find.text('Correct!'), findsOneWidget);

      // Continue to reflection
      await tapKey(tester, 'continue-after-answer');
      await tapKey(tester, 'complete-lesson');
      await tester.enterText(
        find.byKey(const ValueKey('lesson-reflection')),
        'Momentum is conserved in isolated physical collisions.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'lesson-reflection-review');
      await tapKey(tester, 'complete-lesson');

      expect(find.text('Completed: 50 XP'), findsOneWidget);
      expect(api.submitted, [r'$6\text{ N}$', r'$20\text{ kg}\cdot\text{m/s}$']);
      expect(tester.takeException(), isNull);
    },
  );
}

class StemMultiSectionApi implements LearningApi {
  final submitted = <String>[];

  @override
  Future<LessonDetail> lesson(String id) async => const LessonDetail(
    id: 'stem-multi',
    title: 'Newtonian Dynamics',
    categoryId: 'physics',
    categoryName: 'Physics',
    description:
        '## Introduction to Force\nForce is a vector quantity: \$F = m \\cdot a\$.\n\n## Momentum and Impulse\nMomentum is mass times velocity: \$p = m \\cdot v\$.',
    difficulty: LessonDifficulty.medium,
    baseXp: 30,
    reflectionPrompt: 'Reflect on momentum in daily life.',
    exercises: [
      LessonExercise(
        id: 'stem-ex-1',
        question: r'Given $m = 2\text{ kg}$ and $a = 3\text{ m/s}^2$, find $F$.',
        difficulty: LessonDifficulty.easy,
        points: 10,
        completed: false,
        sectionIndex: 1,
        type: LessonExerciseType.multipleChoice,
        options: [r'$5\text{ N}$', r'$6\text{ N}$'],
      ),
      LessonExercise(
        id: 'stem-ex-2',
        question: r'Given $m = 4\text{ kg}$ and $v = 5\text{ m/s}$, find $p$.',
        difficulty: LessonDifficulty.easy,
        points: 10,
        completed: false,
        sectionIndex: 2,
        type: LessonExerciseType.multipleChoice,
        options: [r'$20\text{ kg}\cdot\text{m/s}$', r'$9\text{ kg}\cdot\text{m/s}$'],
      ),
    ],
  );

  @override
  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) async {
    submitted.add(answer);
    final isCorrect = answer == r'$6\text{ N}$' || answer == r'$20\text{ kg}\cdot\text{m/s}$';
    return LessonAnswerResult(
      exerciseId: exerciseId,
      correct: isCorrect,
      points: 10,
      message: isCorrect ? 'Correct!' : 'Try again.',
      explanation: 'Computed using fundamental formula.',
    );
  }

  @override
  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required String reflectionText,
  }) async => const LessonCompletionResult(xpEarned: 50);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

