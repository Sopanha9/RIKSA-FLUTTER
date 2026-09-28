import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/sound/sound_player.dart';
import 'package:riksa_app/core/sound/sound_provider.dart';
import 'package:riksa_app/core/sound/sound_service.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';
import 'package:riksa_app/features/learning/presentation/widgets/learning_atoms.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_experience_screen.dart';
import 'package:riksa_app/features/learning/presentation/learning_result_screens.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/mascot/domain/buddy_care.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/mascot_view.dart';
import 'package:riksa_app/features/mascot/providers/buddy_care_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:riksa_app/features/resources/data/resource_models.dart';
import 'package:riksa_app/features/resources/data/resources_api.dart';
import 'package:riksa_app/features/resources/providers/lesson_resources_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _description = '''
## Newton's second law

A net force changes an object's motion. The bigger the mass, the smaller the
change that same force produces.

**F = m a** relates the three quantities you will use for the rest of this unit.

## Working with the law

Rearranging is where most marks are won or lost, so practise it both ways
before the exam.
''';

const _detail = LessonDetail(
  id: 'physics-2',
  title: 'Forces and Motion',
  description: _description,
  difficulty: LessonDifficulty.medium,
  baseXp: 40,
  categoryId: 'physics',
  categoryName: 'Physics',
  reflectionPrompt: '',
  exercises: [
    LessonExercise(
      id: 'ex-1',
      question: 'A 2 kg trolley accelerates at 3 m/s². What is the net force?',
      difficulty: LessonDifficulty.medium,
      points: 10,
      completed: false,
      sectionIndex: 1,
      type: LessonExerciseType.multipleChoice,
      options: ['1.5 N', '5 N', '6 N', '9 N'],
    ),
    LessonExercise(
      id: 'ex-2',
      question:
          'Doubling the mass under the same force halves the '
          'acceleration.',
      difficulty: LessonDifficulty.easy,
      points: 10,
      completed: false,
      sectionIndex: 2,
      type: LessonExerciseType.trueFalse,
    ),
  ],
);

class _PreviewLearningApi implements LearningApi {
  @override
  Future<LessonDetail> lesson(String lessonId) async => _detail;

  @override
  Future<ContinueLearningResponse> continueLearning() =>
      throw UnimplementedError();

  @override
  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required String reflectionText,
  }) => throw UnimplementedError();

  @override
  Future<List<LearningCategory>> categories() => throw UnimplementedError();

  @override
  Future<LessonPage> listLessons({
    String? categoryId,
    LessonDifficulty? difficulty,
    int? grade,
    int page = 0,
    int size = 20,
  }) => throw UnimplementedError();

  @override
  Future<LearningRoadmap> roadmap(String categoryId) async =>
      LearningRoadmap.fromJson({
        'categoryId': 'physics',
        'categoryName': 'Physics',
        'currentLessonId': 'next',
        'units': [
          {
            'lessons': [
              {
                'id': 'next',
                'title': 'Momentum and collisions',
                'status': 'AVAILABLE',
                'estimatedMinutes': 10,
              },
            ],
          },
        ],
      });

  @override
  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) async => LessonAnswerResult(
    exerciseId: exerciseId,
    correct: true,
    points: 10,
    message: 'Correct.',
    explanation: 'Use the relationship between force, mass and acceleration.',
  );

  @override
  Future<LessonAnswerResult> checkAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) =>
      submitAnswer(lessonId: lessonId, exerciseId: exerciseId, answer: answer);
}

class _PreviewResourcesRepository implements ResourcesRepository {
  @override
  Future<LessonResourcePage> list(String lessonId, {String? cursor}) async =>
      const LessonResourcePage(edges: [], hasNextPage: false);

  @override
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> report(String id) => throw UnimplementedError();

  @override
  Future<LessonResource> save(String id) => throw UnimplementedError();

  @override
  Future<LessonResource> unsave(String id) => throw UnimplementedError();
}

class _PreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'preview-learner',
      username: 'preview',
      displayName: 'Preview',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _PreviewBuddyCareNotifier extends BuddyCareNotifier {
  @override
  BuddyCareState build() => BuddyCareState(
    care: BuddyCare(
      energy: 60,
      bond: 15,
      updatedAt: DateTime.now(),
      careDay: phnomPenhCareDay(DateTime.now()),
    ),
    species: MascotSpecies.crocodile,
    name: 'Croco',
  );
}

Future<void> _loadFonts() async {
  final redditSans = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
  final khmer = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  final khmerTitle = FontLoader(RiksaTypography.khmerTitleFamily)
    ..addFont(rootBundle.load('assets/fonts/Koulen-Regular.ttf'));
  final khmerBody = FontLoader(RiksaTypography.khmerBodyFamily)
    ..addFont(rootBundle.load('assets/fonts/KhmerOS_siemreap.ttf'));
  await Future.wait([
    redditSans.load(),
    khmer.load(),
    materialIcons.load(),
    khmerTitle.load(),
    khmerBody.load(),
  ]);
}

Widget _previewApp({
  ThemeData? theme,
  Widget? home,
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
}) => ProviderScope(
  overrides: [
    // Tests have no audio plugin. Sound preferences load asynchronously, so a
    // fast answer can play a cue before "sound off" is read back.
    soundServiceProvider.overrideWithValue(
      SoundService(createPlayer: _SilentPlayer.new, enableHaptics: false),
    ),
    learningApiProvider.overrideWithValue(_PreviewLearningApi()),
    resourcesRepositoryProvider.overrideWithValue(
      _PreviewResourcesRepository(),
    ),
    authProvider.overrideWith(_PreviewAuthNotifier.new),
    buddyCareProvider.overrideWith(_PreviewBuddyCareNotifier.new),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: scaler, disableAnimations: true),
      child: child!,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: home ?? const LessonExperienceScreen(lessonId: 'physics-2'),
  ),
);

/// The buddy scene and sprites are asset images that decode off the test
/// clock; without this a golden catches the scene before it has painted.
Future<void> _precacheImages(WidgetTester tester) async {
  final images = find.descendant(
    of: find.byType(LessonExperienceScreen),
    matching: find.byType(Image, skipOffstage: false),
  );
  await tester.runAsync(
    () => Future.wait([
      for (final element in images.evaluate())
        precacheImage((element.widget as Image).image, element),
    ]),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'riksa_learning_sound_enabled': false,
    }),
  );

  testWidgets('lesson reading and practice steps', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_previewApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_reading_en_light.png'),
    );

    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pumpAndSettle();
    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_working_en_light.png'),
    );
    await tester.tap(find.byKey(const ValueKey('show-choices')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('lesson-option-2')));
    await tester.tap(find.byKey(const ValueKey('lesson-option-2')));
    await tester.pumpAndSettle();

    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_practice_en_light.png'),
    );
    await tester.tap(find.byKey(const ValueKey('check-answer')));
    await tester.pumpAndSettle();
    expect(find.text('Correct!').hitTestable(), findsOneWidget);
    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_feedback_en_light.png'),
    );
    await tester.tap(find.byKey(const ValueKey('continue-after-answer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-to-section-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-section-2')));
    await tester.pumpAndSettle();
    final paperButton = find.byKey(
      const ValueKey('lesson-worked-on-paper-ex-2'),
    );
    await tester.tap(find.byKey(const ValueKey('lesson-options')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(paperButton);
    await tester.tap(paperButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('lesson-option-0')));
    await tester.tap(find.byKey(const ValueKey('lesson-option-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('check-answer')));
    await tester.pumpAndSettle();
    expect(find.text('Correct!').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continue-after-answer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-reflection-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('lesson-reflection')),
      'Force depends on both mass and acceleration. I want to practise rearranging the formula.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_reflection_en_light.png'),
    );
  });

  testWidgets('lesson reading step in dark', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_previewApp(theme: AppTheme.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _precacheImages(tester);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_reading_en_dark.png'),
    );
  });

  testWidgets('lesson flow supports Khmer at 2x text scale', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _previewApp(
        locale: const Locale('km'),
        scaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LessonExperienceScreen), findsOneWidget);
  });

  testWidgets('completion makes the next lesson clear', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _previewApp(
        home: const LessonCompletionScreen(
          xpEarned: 40,
          lessonTitle: 'Forces and Motion',
          roadmapCategoryId: 'physics',
          lessonId: 'physics-2',
          reflection:
              'Force depends on both mass and acceleration. I want to practise rearranging the formula.',
          needsReview: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final mascotImages = find.descendant(
      of: find.byType(MascotView, skipOffstage: false),
      matching: find.byType(Image, skipOffstage: false),
    );
    await tester.runAsync(
      () => Future.wait([
        for (final element in mascotImages.evaluate())
          precacheImage((element.widget as Image).image, element),
      ]),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LessonCompletionScreen),
      matchesGoldenFile('goldens/lesson_completion_en_light.png'),
    );
  });

  testWidgets('completion in Khmer dark keeps the reward together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _previewApp(
        theme: AppTheme.dark,
        locale: const Locale('km'),
        home: const LessonCompletionScreen(
          xpEarned: 40,
          lessonTitle: 'Forces and Motion',
          roadmapCategoryId: 'physics',
          lessonId: 'physics-2',
          reflection:
              'Force depends on both mass and acceleration. I want to practise rearranging the formula.',
          needsReview: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final mascotImages = find.descendant(
      of: find.byType(MascotView, skipOffstage: false),
      matching: find.byType(Image, skipOffstage: false),
    );
    await tester.runAsync(
      () => Future.wait([
        for (final element in mascotImages.evaluate())
          precacheImage((element.widget as Image).image, element),
      ]),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LessonCompletionScreen),
      matchesGoldenFile('goldens/lesson_completion_km_dark.png'),
    );
  });
  for (final locale in ['en', 'km']) {
    testWidgets('friendly empty state in $locale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _previewApp(
          locale: Locale(locale),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: SafeArea(
                  child: IllustratedEmptyState(
                    title: l10n.savedLessonsEmptyTitle,
                    body: l10n.savedLessonsEmptyBody,
                    actionLabel: l10n.lessonStartAction,
                    onAction: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/learning_empty_${locale}_light.png'),
      );
    });
  }

  testWidgets('busy button keeps its action color and explains the wait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _previewApp(
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: LearningPrimaryButton(
                label: 'Save and finish',
                busy: true,
                onPressed: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/learning_busy_en_light.png'),
    );
  });
}

class _SilentPlayer implements SoundPlayer {
  @override
  Future<void> play(String asset) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
