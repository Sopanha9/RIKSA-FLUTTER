import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_result_screens.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

LearningRoadmap roadmap({String status = 'AVAILABLE'}) =>
    LearningRoadmap.fromJson({
      'categoryId': 'biology',
      'categoryName': 'Biology',
      'currentLessonId': 'next',
      'units': [
        {
          'lessons': [
            {
              'id': 'next',
              'title': 'Cell division',
              'status': status,
              'estimatedMinutes': 8,
            },
          ],
        },
      ],
    });

Widget completionApp({
  Locale locale = const Locale('en'),
  bool failed = false,
  String status = 'AVAILABLE',
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final router = GoRouter(
    initialLocation: '/complete',
    routes: [
      GoRoute(
        path: '/complete',
        builder: (_, _) => const LessonCompletionScreen(
          xpEarned: 35,
          lessonId: 'done',
          lessonTitle: 'Cell Biology & Organelles',
          roadmapCategoryId: 'biology',
          reflection: 'Cells are the basic unit of life.',
          needsReview: true,
        ),
      ),
      GoRoute(
        path: '/learn/next',
        builder: (_, _) => const Scaffold(body: Text('Next lesson opened')),
      ),
      GoRoute(
        path: '/learn/roadmap/biology',
        builder: (_, _) => const Scaffold(body: Text('Roadmap opened')),
      ),
      GoRoute(
        path: '/learn',
        builder: (_, _) => const Scaffold(body: Text('Learning home')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      learningRoadmapProvider('biology').overrideWith((_) async {
        if (failed) throw Exception('offline');
        return roadmap(status: status);
      }),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
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
    ),
  );
}

void main() {
  testWidgets(
    'shows the saved reflection and opens the server recommended lesson',
    (tester) async {
      await tester.pumpWidget(completionApp());
      await tester.pumpAndSettle();
      expect(find.text('Lesson completed'), findsOneWidget);
      expect(find.text('Cells are the basic unit of life.'), findsOneWidget);
      expect(find.text('Cell division'), findsOneWidget);
      expect(find.text('Lesson Mastered!'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('lesson-completion-continue')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Next lesson opened'), findsOneWidget);
    },
  );

  for (final status in ['LOCKED', 'COMPLETED']) {
    testWidgets('does not recommend a $status lesson', (tester) async {
      await tester.pumpWidget(completionApp(status: status));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('lesson-completion-next-title')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('lesson-completion-continue')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Roadmap opened'), findsOneWidget);
    });
  }

  testWidgets('recommendation failure leaves a usable roadmap action', (
    tester,
  ) async {
    await tester.pumpWidget(completionApp(failed: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-completion-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Roadmap opened'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer completion fits 360dp at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      completionApp(
        locale: const Locale('km'),
        textScaler: TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start next lesson'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
