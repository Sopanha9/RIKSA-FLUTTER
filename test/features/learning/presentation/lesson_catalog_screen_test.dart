import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_shell.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_catalog_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _SignedInNotifier extends AuthNotifier {
  @override
  AuthState build() => Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sokha',
      email: 'sokha@example.com',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      createdAt: DateTime.utc(2026),
    ),
  );
}

LessonSummary _lesson({
  required String id,
  required String title,
  required String category,
  bool completed = false,
  double? progress,
  int? minutes,
}) => LessonSummary(
  id: id,
  title: title,
  description: '',
  difficulty: LessonDifficulty.easy,
  baseXp: 25,
  categoryId: category.toLowerCase(),
  categoryName: category,
  exerciseCount: 0,
  completed: completed,
  createdAt: null,
  durationMinutes: minutes,
  progress: progress,
);

final _math = SubjectProgress(
  category: const LearningCategory(id: 'math', name: 'Mathematics'),
  completed: 1,
  total: 3,
  currentLessonId: 'm2',
  lessons: [
    _lesson(id: 'm1', title: 'Antiderivatives', category: 'Mathematics', completed: true),
    _lesson(
      id: 'm2',
      title: 'Definite integrals and area',
      category: 'Mathematics',
      progress: .43,
      minutes: 8,
    ),
    _lesson(id: 'm3', title: 'Volumes of revolution', category: 'Mathematics'),
  ],
);

final _biology = SubjectProgress(
  category: const LearningCategory(id: 'biology', name: 'Biology'),
  completed: 0,
  total: 1,
  lessons: [
    _lesson(id: 'b1', title: 'ស្វែងយល់ពីកោសិកា', category: 'Biology'),
  ],
);

final _offline = SubjectProgress(
  category: const LearningCategory(id: 'physics', name: 'Physics'),
  lessons: const [],
  unavailable: true,
);

LearningHomeData _home({List<SubjectProgress>? subjects}) {
  final list = subjects ?? [_math, _biology, _offline];
  final resume = list.firstWhere(
    (subject) => subject.resumable != null,
    orElse: () => list.first,
  );
  return LearningHomeData(
    subjects: list,
    resumeSubject: resume.resumable == null ? null : resume,
    resumeLesson: resume.resumable,
  );
}

Widget _app({
  required GoRouter router,
  required Future<LearningHomeData> Function() home,
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_SignedInNotifier.new),
    communityStreakProvider.overrideWith(
      (ref) async => const CommunityStreak(current: 12, highest: 21),
    ),
    learningHomeProvider.overrideWith((ref) => home()),
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
);

GoRouter _router() => GoRouter(
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
          builder: (_, state) =>
              Scaffold(body: Text('lesson-${state.pathParameters['id']}')),
        ),
      ],
    ),
  ],
);

void _sizePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('offers one lesson to resume and the subject index', (
    tester,
  ) async {
    _sizePhone(tester);
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(router: router, home: () async => _home()),
    );
    await tester.pumpAndSettle();

    // Exactly one resumable lesson is offered, and it is the started one.
    expect(find.byKey(const ValueKey('continue-lesson-m2')), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-lesson-m1')), findsNothing);
    expect(find.text('Definite integrals and area'), findsOneWidget);

    // Every subject appears, including the one whose roadmap failed to load.
    expect(find.byKey(const ValueKey('subject-tile-math')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-tile-biology')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-tile-physics')), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Could not load'), findsOneWidget);

    // The destination never scrolls away, and it aggregates every subject.
    expect(
      find.byKey(const ValueKey('learning-destination-bar')),
      findsOneWidget,
    );
    expect(find.text('1 of 4 lessons'), findsOneWidget);

    expect(find.byKey(const ValueKey('learning-streak-chip')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('continue opens the lesson, a tile opens the roadmap', (
    tester,
  ) async {
    _sizePhone(tester);
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(router: router, home: () async => _home()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continue-lesson-m2')));
    await tester.pumpAndSettle();
    expect(find.text('lesson-m2'), findsOneWidget);

    router.go('/learn');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('subject-tile-biology')));
    await tester.pumpAndSettle();
    expect(find.text('roadmap-biology'), findsOneWidget);
  });

  testWidgets('renders Khmer subject titles with the Khmer display face', (
    tester,
  ) async {
    _sizePhone(tester);
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        home: () async => _home(
          subjects: [
            SubjectProgress(
              category: const LearningCategory(
                id: 'khmer-science',
                name: 'ជីវវិទ្យា',
              ),
              completed: 0,
              total: 1,
              lessons: [
                _lesson(
                  id: 'k1',
                  title: 'ស្វែងយល់ពីកោសិកា',
                  category: 'ជីវវិទ្យា',
                  progress: .2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('subject-tile-khmer-science')),
        matching: find.text('ជីវវិទ្យា'),
      ),
    );
    expect(title.style?.fontFamily, RiksaTypography.khmerTitleFamily);

    // The Khmer lesson title on the resume card gets the same treatment, so a
    // long Khmer title cannot fall back to the Latin face mid-screen.
    final resumeTitle = tester.widget<Text>(find.text('ស្វែងយល់ពីកោសិកា'));
    expect(resumeTitle.style?.fontFamily, RiksaTypography.khmerTitleFamily);
    expect(tester.takeException(), isNull);
  });

  testWidgets('surfaces a retry when the whole screen fails to load', (
    tester,
  ) async {
    _sizePhone(tester);
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(router: router, home: () async => throw StateError('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.text('We couldn’t load lessons'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('replaces the resume card once every subject is finished', (
    tester,
  ) async {
    _sizePhone(tester);
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        home: () async => _home(
          subjects: [
            SubjectProgress(
              category: const LearningCategory(
                id: 'math',
                name: 'Mathematics',
              ),
              completed: 1,
              total: 1,
              lessons: [
                _lesson(
                  id: 'm1',
                  title: 'Antiderivatives',
                  category: 'Mathematics',
                  completed: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every subject is finished'), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-lesson-m1')), findsNothing);
  });

  testWidgets('keeps the greeting below the device top inset', (tester) async {
    _sizePhone(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_SignedInNotifier.new),
          learningHomeProvider.overrideWith((ref) async => _home()),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 3, highest: 9),
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
      tester.getTopLeft(find.text('Hi, Sokha')).dy,
      greaterThanOrEqualTo(59),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping home avatar opens profile drawer', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_SignedInNotifier.new),
          learningHomeProvider.overrideWith((ref) async => _home()),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 3, highest: 9),
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
          home: AppShellScope(
            openDrawer: () => opened = true,
            child: const LessonCatalogScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatarButton = find.byKey(const ValueKey('home-avatar-button'));
    expect(avatarButton, findsOneWidget);
    await tester.tap(avatarButton);
    await tester.pump();

    expect(opened, isTrue);
  });
}
