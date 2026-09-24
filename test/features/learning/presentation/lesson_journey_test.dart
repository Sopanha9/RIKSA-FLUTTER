import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_experience_screen.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:riksa_app/features/learning/presentation/widgets/learning_atoms.dart';
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

class _AuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'learner-1',
      username: 'learner',
      displayName: 'Learner',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _GuestNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

Widget journeyApp(
  JourneyApi api, {
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
  bool authenticated = true,
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
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const Scaffold(body: Text('Sign in required')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      learningApiProvider.overrideWithValue(api),
      authProvider.overrideWith(
        authenticated ? _AuthenticatedNotifier.new : _GuestNotifier.new,
      ),
    ],
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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: scaler, disableAnimations: true),
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
      expect(find.byKey(const ValueKey('lesson-option-0')), findsNothing);
      await tapKey(tester, 'lesson-add-working-force-1');
      expect(
        find.byKey(const ValueKey('lesson-working-force-1')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('lesson-working-force-1')),
        '2 × 3 = 6 N',
      );
      await tapKey(tester, 'compare-answers');
      expect(find.byKey(const ValueKey('lesson-option-0')), findsOneWidget);
      await tapKey(tester, 'lesson-option-0');
      await tapKey(tester, 'check-answer');
      expect(find.text('Try again.'), findsOneWidget);
      await tapKey(tester, 'lesson-edit-working-force-1');
      expect(find.text('2 × 3 = 6 N'), findsOneWidget);
      await tapKey(tester, 'compare-answers');
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

  testWidgets('guest answer asks for sign in without submitting to the API', (
    tester,
  ) async {
    final api = JourneyApi();
    await tester.pumpWidget(journeyApp(api, authenticated: false));
    await tester.pumpAndSettle();

    await tapKey(tester, 'start-section-1');
    await tapKey(tester, 'lesson-worked-on-paper-force-1');
    await tapKey(tester, 'lesson-option-0');
    await tapKey(tester, 'check-answer');

    expect(find.text('Sign in required'), findsOneWidget);
    expect(api.submitted, isEmpty);
  });

  testWidgets(
    'a confidence tap completes the lesson with an empty reflection',
    (tester) async {
      final api = JourneyApi();
      await tester.pumpWidget(journeyApp(api));
      await tester.pumpAndSettle();

      await tapKey(tester, 'start-section-1');
      await tapKey(tester, 'lesson-worked-on-paper-force-1');
      await tapKey(tester, 'lesson-option-1');
      await tapKey(tester, 'check-answer');
      await tapKey(tester, 'continue-after-answer');

      expect(find.byKey(const ValueKey('lesson-reflection')), findsOneWidget);
      final save = tester.widget<LearningPrimaryButton>(
        find.byKey(const ValueKey('complete-lesson')),
      );
      expect(save.onPressed, isNull);

      await tapKey(tester, 'lesson-reflection-confident');
      final enabledSave = tester.widget<LearningPrimaryButton>(
        find.byKey(const ValueKey('complete-lesson')),
      );
      expect(enabledSave.onPressed, isNotNull);
      await tapKey(tester, 'complete-lesson');

      expect(api.reflections, hasLength(1));
      expect(api.reflections.single, contains('[I can explain it]'));
      expect(find.text('Saved: '), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Khmer reading and reflection fit 360dp at 200 percent text', (
    tester,
  ) async {
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
    await tapKey(tester, 'lesson-worked-on-paper-force-1');
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'lesson-option-1');
    await tapKey(tester, 'check-answer');
    await tapKey(tester, 'continue-after-answer');
    expect(find.byKey(const ValueKey('lesson-reflection')), findsOneWidget);
    await tapKey(tester, 'lesson-reflection-review');
    expect(tester.takeException(), isNull);
  });
}
