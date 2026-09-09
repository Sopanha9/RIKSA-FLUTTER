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

const _khmerDescription = '''
# កោសិកា និងសរីរាង្គកោសិកា (Cell Biology & Organelles)

**កោសិកា (Cell)** គឺជាឯកតាគ្រឹះនៃរូបរាង និងមុខងារ។

---

### ១. សមាសភាពសំខាន់ៗនៃកោសិកា
- **ភ្នាសកោសិកា (Cell Membrane):** គ្រប់គ្រងការចេញចូល។

| សរីរាង្គ | កោសិកាសត្វ |
|:---|:---|
| ជញ្ជាំងកោសិកា | គ្មាន |
''';

const _detail = LessonDetail(
  id: 'biology-1',
  title: 'ជីវវិទ្យាកោសិកា (Cell Biology)',
  description: _khmerDescription,
  difficulty: LessonDifficulty.easy,
  baseXp: 30,
  categoryId: 'biology',
  categoryName: 'ជីវវិទ្យា',
  reflectionPrompt: '',
  exercises: [],
);

class _FakeLearningApi implements LearningApi {
  @override
  Future<ContinueLearningResponse> continueLearning() =>
      throw UnimplementedError();

  @override
  Future<LessonDetail> lesson(String lessonId) async => _detail;

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

class _FakeLearningApiWithExercises extends _FakeLearningApi {
  @override
  Future<LessonDetail> lesson(String lessonId) async => const LessonDetail(
    id: 'biology-1',
    title: 'Cell Biology',
    description: '# Section 1\n\nIntro to cell',
    difficulty: LessonDifficulty.easy,
    baseXp: 30,
    categoryId: 'biology',
    categoryName: 'Biology',
    reflectionPrompt: '',
    exercises: [
      LessonExercise(
        id: 'ex-1',
        type: LessonExerciseType.multipleChoice,
        question: 'What is a cell?',
        options: ['Unit of life', 'Car'],
        difficulty: LessonDifficulty.easy,
        points: 10,
        completed: false,
        hint: 'Basic unit',
        sectionIndex: 0,
      ),
    ],
  );
}

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span case final TextSpan textSpan) {
    yield textSpan;
    for (final child in textSpan.children ?? const <InlineSpan>[]) {
      yield* _textSpans(child);
    }
  }
}

bool _hasKhmer(String? text) =>
    text != null && RegExp(r'[\u1780-\u17FF\u19E0-\u19FF]').hasMatch(text);

Widget _lessonApp({TextScaler textScaler = TextScaler.noScaling}) => ProviderScope(
  overrides: [learningApiProvider.overrideWithValue(_FakeLearningApi())],
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: const LessonExperienceScreen(lessonId: 'biology-1'),
  ),
);

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Koulen',
    )..addFont(rootBundle.load('assets/fonts/Koulen-Regular.ttf'))).load();
    await (FontLoader('Kantumruy Pro')
          ..addFont(rootBundle.load('assets/fonts/KantumruyPro-Variable.ttf')))
        .load();
  });

  testWidgets('renders Khmer lesson Markdown with the bundled Khmer font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [learningApiProvider.overrideWithValue(_FakeLearningApi())],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const LessonExperienceScreen(lessonId: 'biology-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lesson-description-markdown')),
      findsOneWidget,
    );
    expect(find.textContaining('**កោសិកា'), findsNothing);
    expect(find.text('---'), findsNothing);
    expect(find.textContaining('| សរីរាង្គ |'), findsNothing);
    expect(find.text('១. សមាសភាពសំខាន់ៗនៃកោសិកា'), findsOneWidget);
    expect(find.text('សរីរាង្គ'), findsOneWidget);

    final lessonTitle = tester.widget<Text>(find.text(_detail.title));
    expect(lessonTitle.style?.fontFamily, 'Koulen');

    final markdownEditableText = find.descendant(
      of: find.byKey(const ValueKey('lesson-description-markdown')),
      matching: find.byType(EditableText),
    );
    final khmerElement = markdownEditableText.evaluate().firstWhere(
      (element) => (element.widget as EditableText).controller.text.contains(
        'កោសិកា (Cell)',
      ),
    );
    final khmerText = khmerElement.widget as EditableText;
    final renderedSpan = khmerText.controller.buildTextSpan(
      context: khmerElement,
      withComposing: false,
    );
    final khmerSpans = _textSpans(
      renderedSpan,
    ).where((span) => _hasKhmer(span.text)).toList();
    expect(khmerSpans, isNotEmpty);
    expect(
      khmerSpans.every((span) => span.style?.fontFamily == 'Kantumruy Pro'),
      isTrue,
    );

    final headingElement = markdownEditableText.evaluate().firstWhere(
      (element) => (element.widget as EditableText).controller.text.contains(
        'កោសិកា និងសរីរាង្គកោសិកា',
      ),
    );
    final headingText = headingElement.widget as EditableText;
    final headingSpan = headingText.controller.buildTextSpan(
      context: headingElement,
      withComposing: false,
    );
    final khmerHeadingSpans = _textSpans(
      headingSpan,
    ).where((span) => _hasKhmer(span.text)).toList();
    expect(khmerHeadingSpans, isNotEmpty);
    expect(
      khmerHeadingSpans.every((span) => span.style?.fontFamily == 'Koulen'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('the header keeps progress pinned while the title scrolls away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_lessonApp());
    await tester.pumpAndSettle();

    final track = find.byKey(const ValueKey('lesson-progress-track'));
    final title = find.text(_detail.title);
    final trackTop = tester.getTopLeft(track).dy;
    final titleTop = tester.getTopLeft(title).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();

    // Navigation and progress hold their place; the identity block gives its
    // room to the reading.
    expect(track, findsOneWidget);
    expect(tester.getTopLeft(track).dy, trackTop);
    expect(tester.getTopLeft(title).dy, lessThan(titleTop));
  });

  testWidgets('the header holds at 200% text scale', (tester) async {
    // The narrowest supported width at the largest supported type: the case
    // where a header that guessed its own extent overflows.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _lessonApp(textScaler: const TextScaler.linear(2)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lesson-progress-track')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows exit confirmation dialog when attempting to leave with active practice',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeApi = _FakeLearningApiWithExercises();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [learningApiProvider.overrideWithValue(fakeApi)],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('km')],
            home: const Scaffold(
              body: LessonExperienceScreen(lessonId: 'biology-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap practice button in action bar to enter practice phase
      final practiceButton = find.text('Practice this section');
      expect(practiceButton, findsOneWidget);
      await tester.tap(practiceButton);
      await tester.pumpAndSettle();

      // Tap the back button
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Leave this lesson?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('leave-lesson-cancel-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('leave-lesson-confirm-button')),
        findsOneWidget,
      );

      // Tap keep learning to dismiss
      await tester.tap(find.byKey(const ValueKey('leave-lesson-cancel-button')));
      await tester.pumpAndSettle();
      expect(find.text('Leave this lesson?'), findsNothing);

      // Tap back again and confirm leave
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.text('Leave this lesson?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('leave-lesson-confirm-button')));
      await tester.pumpAndSettle();
    },
  );
}
