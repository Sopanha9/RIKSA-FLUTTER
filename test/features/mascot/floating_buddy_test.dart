import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/floating_buddy.dart';
import 'package:riksa_app/features/quests/data/quest_models.dart';
import 'package:riksa_app/features/quests/data/quests_api.dart';
import 'package:riksa_app/features/quests/providers/today_quests_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows on learning home and hides on a lesson route', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_app(router: router));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('floating-buddy-head')), findsOneWidget);

    router.go('/learn/lesson-1');
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-buddy-head')), findsNothing);
  });

  testWidgets('hides on a subject map, which has its own buddy', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_app(router: router));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('floating-buddy-head')), findsOneWidget);

    router.go('/learn/roadmap/math-id');
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-buddy-head')), findsNothing);

    router.go('/learn/subject/MATHEMATICS');
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-buddy-head')), findsNothing);
  });

  testWidgets('guest sheet previews quests without calling the API', (
    tester,
  ) async {
    final repository = _FakeQuestsRepository();
    await tester.pumpWidget(
      _app(
        router: _router(),
        repository: repository,
        locale: const Locale('en'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Save your streak — sign in'), findsOneWidget);
    expect(repository.todayCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the claimable quest badge count', (tester) async {
    final repository = _FakeQuestsRepository(claimableCount: 2);
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('2'), findsOneWidget);
    expect(repository.todayCalls, 1);
  });

  testWidgets('claim button submits the selected quest', (tester) async {
    final repository = _FakeQuestsRepository(claimableCount: 1);
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Claim').first);
    await tester.pump();
    await tester.tap(find.text('Claim'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.claimedIds, ['quest-0']);
    expect(find.text('Claimed'), findsOneWidget);
  });

  testWidgets('dragging snaps the head to the nearest edge', (tester) async {
    await tester.pumpWidget(_app(router: _router()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(
      find.byKey(const ValueKey('floating-buddy-head')),
      const Offset(620, 30),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-buddy-head'))).dx,
      greaterThan(400),
    );
  });

  testWidgets('Khmer sheet at 200% text scale stays scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(router: _router(), locale: const Locale('km'), textScale: 2),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('រក្សាស្ទ្រីករបស់អ្នក — ចូលគណនី'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required GoRouter router,
  _FakeQuestsRepository? repository,
  String? userId,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    if (userId != null) authProvider.overrideWith(_LoggedInNotifier.new),
    currentUserIdProvider.overrideWithValue(userId),
    if (repository != null)
      questsRepositoryProvider.overrideWithValue(repository),
    profileDashboardProvider.overrideWith(
      (ref) async => const ProfileDashboardData(
        gamification: GamificationProfile(
          totalXp: 0,
          currentStreak: 5,
          highestStreak: 5,
          xpToNext: 100,
        ),
        achievements: [],
        activities: [],
      ),
    ),
  ],
  child: MaterialApp.router(
    routerConfig: router,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  ),
);

GoRouter _router() => GoRouter(
  initialLocation: '/learn',
  routes: [
    GoRoute(path: '/learn', builder: (_, _) => const _LearningPage()),
    GoRoute(path: '/learn/:id', builder: (_, _) => const _LearningPage()),
    GoRoute(
      path: '/learn/roadmap/:id',
      builder: (_, _) => const _LearningPage(),
    ),
    GoRoute(
      path: '/learn/subject/:id',
      builder: (_, _) => const _LearningPage(),
    ),
    GoRoute(path: '/auth/login', builder: (_, _) => const Scaffold()),
  ],
);

class _LearningPage extends StatelessWidget {
  const _LearningPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Stack(children: [Text('Learning home'), FloatingBuddy()]),
  );
}

class _LoggedInNotifier extends AuthNotifier {
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

class _FakeQuestsRepository implements QuestsRepository {
  _FakeQuestsRepository({this.claimableCount = 0});

  final int claimableCount;
  int todayCalls = 0;
  final List<String> claimedIds = [];

  @override
  Future<TodayQuests> today() async {
    todayCalls++;
    return TodayQuests(
      date: DateTime(2026, 9, 24),
      allClaimedBonusXp: 30,
      quests: [
        for (var i = 0; i < 3; i++)
          DailyQuest(
            id: 'quest-$i',
            type: DailyQuestType.values[i],
            title: 'Quest $i',
            titleKm: 'កិច្ចការ $i',
            target: 1,
            progress: i < claimableCount ? 1 : 0,
            xpReward: 10,
            completed: i < claimableCount,
            claimed: false,
          ),
      ],
    );
  }

  @override
  Future<DailyQuest> claim(String id) async {
    claimedIds.add(id);
    return DailyQuest(
      id: id,
      type: DailyQuestType.completeLesson,
      title: 'Quest',
      titleKm: 'កិច្ចការ',
      target: 1,
      progress: 1,
      xpReward: 10,
      completed: true,
      claimed: true,
    );
  }
}
