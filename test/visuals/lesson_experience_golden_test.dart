import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_experience_screen.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
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
  Future<LearningRoadmap> roadmap(String categoryId) =>
      throw UnimplementedError();

  @override
  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) => throw UnimplementedError();
}

Future<void> _loadFonts() async {
  final poppins = FontLoader(RiksaTypography.latinFamily);
  for (final name in [
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
  }
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
  await Future.wait([poppins.load(), khmer.load(), materialIcons.load()]);
}

Widget _previewApp({ThemeData? theme}) => ProviderScope(
  overrides: [learningApiProvider.overrideWithValue(_PreviewLearningApi())],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: const LessonExperienceScreen(lessonId: 'physics-2'),
  ),
);

void main() {
  setUpAll(_loadFonts);

  testWidgets('lesson reading and practice steps', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_previewApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_reading_en_light.png'),
    );

    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-option-2')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_practice_en_light.png'),
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
    await expectLater(
      find.byType(LessonExperienceScreen),
      matchesGoldenFile('goldens/lesson_reading_en_dark.png'),
    );
  });
}
