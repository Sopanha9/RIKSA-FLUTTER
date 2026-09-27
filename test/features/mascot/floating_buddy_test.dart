import 'package:dio/dio.dart';
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

  testWidgets('head is transparent and keeps a 56px or larger hit target', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_app(router: router));
    await tester.pump(const Duration(milliseconds: 120));

    final head = find.byKey(const ValueKey('floating-buddy-head'));
    final hitTarget = tester.getSize(head);
    expect(hitTarget.width, greaterThanOrEqualTo(56));
    expect(hitTarget.height, greaterThanOrEqualTo(56));
    expect(
      find.descendant(of: head, matching: find.byType(ClipOval)),
      findsNothing,
    );
    expect(
      find.descendant(of: head, matching: find.byType(ClipRRect)),
      findsNothing,
    );
  });

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

  testWidgets(
    'guest panel previews quests, shows locks, and makes no API calls',
    (tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('buddy-panel-sheet')), findsOneWidget);
      expect(
        find.text('Sign in to keep your streak and rewards.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsAtLeastNWidgets(2));
      expect(repository.todayCalls, 0);
      expect(repository.weekCalls, 0);
      expect(repository.claimedIds, isEmpty);
      expect(repository.weeklyClaimedIds, isEmpty);
      expect(repository.chestOpenCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guest lock routes through the account gate', (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(router: router));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // push() stacks a match without changing the base URL; read the top.
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/auth/login',
    );
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

  testWidgets('claim action submits a daily quest and refreshes its row', (
    tester,
  ) async {
    final repository = _FakeQuestsRepository(claimableCount: 1);
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Claim').first);
    await tester.tap(find.text('Claim').first);
    await tester.pump(const Duration(milliseconds: 250));

    expect(repository.claimedIds, ['quest-0']);
    expect(find.text('Claimed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly tab shows quests and claims a weekly quest', (
    tester,
  ) async {
    final repository = _FakeQuestsRepository(weeklyClaimable: true);
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('buddy-tab-week')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Weekly lesson quest'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-tab-today')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Quest 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-tab-week')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Weekly lesson quest'), findsOneWidget);
    await tester.ensureVisible(find.text('Claim').first);
    await tester.tap(find.text('Claim').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.weeklyClaimedIds, ['weekly-quest-0']);
    expect(find.text('Claimed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chest opens at 15/15 and shows its reward', (tester) async {
    final repository = _FakeQuestsRepository(chestReady: true);
    _setScreen(tester, const Size(900, 420));
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.chestOpenCalls, 1);
    expect(find.text('+50 XP earned'), findsOneWidget);
    // The reward is announced in a sentence that links to the wardrobe.
    expect(find.textContaining('Sprout cap'), findsOneWidget);
  });

  testWidgets('409 chest response keeps the chest available', (tester) async {
    final repository = _FakeQuestsRepository(
      chestReady: true,
      failChestOpen: true,
    );
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(
      _app(router: _router(), repository: repository, userId: 'learner-1'),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 180));

    expect(repository.chestOpenCalls, 1);
    expect(
      find.text('The chest could not be opened. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Go navigates and closes the panel', (tester) async {
    final router = _router();
    await tester.pumpWidget(
      _app(
        router: router,
        repository: _FakeQuestsRepository(),
        userId: 'learner-1',
      ),
    );
    await tester.pump(const Duration(milliseconds: 140));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final socialRow = find.byKey(const ValueKey('buddy-quest-quest-2'));
    await tester.ensureVisible(
      find.descendant(of: socialRow, matching: find.text('Go →')),
    );
    await tester.tap(
      find.descendant(of: socialRow, matching: find.text('Go →')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(router.routeInformationProvider.value.uri.path, '/social');
    expect(find.byKey(const ValueKey('buddy-panel')), findsNothing);
  });

  testWidgets(
    'popup opens downward from a left-edge head and stays on screen',
    (tester) async {
      _setScreen(tester, const Size(420, 900));
      await tester.pumpWidget(_app(router: _router()));
      await tester.pump(const Duration(milliseconds: 140));
      await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final panel = tester.getRect(find.byKey(const ValueKey('buddy-panel')));
      expect(
        find.byKey(const ValueKey('buddy-panel-tail-top')),
        findsOneWidget,
      );
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.top, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(420));
      expect(panel.bottom, lessThanOrEqualTo(796));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('right-edge head opens an on-screen panel aligned right', (
    tester,
  ) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(_app(router: _router()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.drag(
      find.byKey(const ValueKey('floating-buddy-head')),
      const Offset(360, 24),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final panel = tester.getRect(find.byKey(const ValueKey('buddy-panel')));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-buddy-head'))).dx,
      greaterThan(300),
    );
    expect(panel.right, lessThanOrEqualTo(420));
    expect(panel.left, greaterThan(0));
  });

  testWidgets('bottom-half head opens the bubble upward', (tester) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(_app(router: _router()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.drag(
      find.byKey(const ValueKey('floating-buddy-head')),
      const Offset(0, 500),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final panel = tester.getRect(find.byKey(const ValueKey('buddy-panel')));
    expect(
      find.byKey(const ValueKey('buddy-panel-tail-bottom')),
      findsOneWidget,
    );
    expect(panel.top, greaterThanOrEqualTo(12));
    expect(panel.bottom, lessThanOrEqualTo(900));
  });

  testWidgets('back closes the popup', (tester) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(_app(router: _router()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('buddy-panel')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('buddy-panel')), findsNothing);
  });

  testWidgets('tapping the talking head closes the popup', (tester) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(_app(router: _router()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('buddy-panel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buddy-panel-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('buddy-panel')), findsNothing);
  });

  testWidgets('200% Khmer text uses the scrollable fallback without overflow', (
    tester,
  ) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(
      _app(router: _router(), locale: const Locale('km'), textScale: 2),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('buddy-panel-sheet')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('buddy-panel-sheet'))).bottom,
      lessThanOrEqualTo(796),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps a static XP reward label', (tester) async {
    _setScreen(tester, const Size(420, 900));
    await tester.pumpWidget(
      _app(
        router: _router(),
        repository: _FakeQuestsRepository(claimableCount: 1),
        userId: 'learner-1',
        reducedMotion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump(const Duration(milliseconds: 180));
    await tester.ensureVisible(find.text('Claim').first);
    await tester.tap(find.text('Claim').first);
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('+10 XP'), findsWidgets);
  });

  testWidgets('dark mode head remains unclipped with a thin outline', (
    tester,
  ) async {
    await tester.pumpWidget(_app(router: _router(), dark: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('floating-buddy-head')),
        matching: find.byType(ClipOval),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer guest fallback remains scrollable', (tester) async {
    _setScreen(tester, const Size(900, 420));
    await tester.pumpWidget(
      _app(router: _router(), locale: const Locale('km'), textScale: 1),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('floating-buddy-head')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('buddy-panel-sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required GoRouter router,
  _FakeQuestsRepository? repository,
  String? userId,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool dark = false,
  bool reducedMotion = false,
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
    theme: dark ? ThemeData.dark() : ThemeData.light(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reducedMotion,
      ),
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
    GoRoute(path: '/social', builder: (_, _) => const Scaffold()),
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

class _FakeQuestsRepository
    implements QuestsRepository, WeeklyQuestsRepository {
  _FakeQuestsRepository({
    this.claimableCount = 0,
    this.weeklyClaimable = false,
    this.chestReady = false,
    this.failChestOpen = false,
  });

  final int claimableCount;
  final bool weeklyClaimable;
  final bool chestReady;
  final bool failChestOpen;
  int todayCalls = 0;
  int weekCalls = 0;
  int chestOpenCalls = 0;
  final Set<String> claimedIds = {};
  final Set<String> weeklyClaimedIds = {};
  bool chestOpened = false;

  @override
  Future<TodayQuests> today() async {
    todayCalls++;
    return TodayQuests(
      date: DateTime(2026, 9, 24),
      resetsAt: DateTime(2026, 9, 25),
      allClaimedBonusXp: 30,
      quests: [
        for (var i = 0; i < 3; i++)
          DailyQuest(
            id: 'quest-$i',
            type: DailyQuestType.values[i],
            title: 'Quest $i',
            titleKm: 'បញ្ចប់មេរៀន $i',
            target: 1,
            progress: i < claimableCount ? 1 : 0,
            xpReward: 10,
            completed: i < claimableCount,
            claimed: claimedIds.contains('quest-$i'),
          ),
      ],
    );
  }

  @override
  Future<DailyQuest> claim(String id) async {
    claimedIds.add(id);
    final index = int.parse(id.split('-').last);
    return DailyQuest(
      id: id,
      type: DailyQuestType.values[index],
      title: 'Quest $index',
      titleKm: 'បញ្ចប់មេរៀន $index',
      target: 1,
      progress: 1,
      xpReward: 10,
      completed: true,
      claimed: true,
    );
  }

  @override
  Future<WeeklyQuests> week() async {
    weekCalls++;
    return WeeklyQuests(
      weekStart: DateTime(2026, 9, 21),
      resetsAt: DateTime(2026, 9, 28),
      quests: [
        WeeklyQuest(
          id: 'weekly-quest-0',
          type: WeeklyQuestType.lessons,
          title: 'Weekly lesson quest',
          titleKm: 'បញ្ចប់មេរៀនប្រចាំសប្តាហ៍',
          target: 1,
          progress: weeklyClaimable ? 1 : 0,
          xpReward: 35,
          completed: weeklyClaimable,
          claimed: weeklyClaimedIds.contains('weekly-quest-0'),
        ),
        WeeklyQuest(
          id: 'weekly-quest-social',
          type: WeeklyQuestType.social,
          title: 'Weekly social quest',
          titleKm: 'សកម្មភាពសង្គមប្រចាំសប្តាហ៍',
          target: 3,
          progress: 1,
          xpReward: 25,
          completed: false,
          claimed: false,
        ),
      ],
      chest: WeeklyChest(
        id: 'chest-1',
        points: chestReady ? 15 : 4,
        target: 15,
        maxPoints: 15,
        opened: chestOpened,
        xpReward: 50,
        rewardItem: chestOpened
            ? const WeeklyRewardItem(
                id: 'hat-1',
                slot: 'HAT',
                assetKey: 'hat.sprout',
                name: 'Sprout cap',
                nameKm: 'មួកស្លឹក',
              )
            : null,
      ),
    );
  }

  @override
  Future<WeeklyQuest> claimWeekly(String id) async {
    weeklyClaimedIds.add(id);
    return WeeklyQuest(
      id: id,
      type: WeeklyQuestType.lessons,
      title: 'Weekly lesson quest',
      titleKm: 'បញ្ចប់មេរៀនប្រចាំសប្តាហ៍',
      target: 1,
      progress: 1,
      xpReward: 35,
      completed: true,
      claimed: true,
    );
  }

  @override
  Future<WeeklyChest> openChest() async {
    chestOpenCalls++;
    if (failChestOpen) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quests/chest/open'),
        response: Response(
          requestOptions: RequestOptions(path: '/quests/chest/open'),
          statusCode: 409,
        ),
      );
    }
    chestOpened = true;
    return const WeeklyChest(
      id: 'chest-1',
      points: 15,
      target: 15,
      maxPoints: 15,
      opened: true,
      xpReward: 50,
      rewardItem: WeeklyRewardItem(
        id: 'hat-1',
        slot: 'HAT',
        assetKey: 'hat.sprout',
        name: 'Sprout cap',
        nameKm: 'មួកស្លឹក',
      ),
    );
  }
}
