import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/language_toggle.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/riksa_profile_drawer.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _user = AuthUser(
  id: 'user-1',
  username: 'sokha',
  displayName: 'Sokha Chan',
  emailVerified: true,
  phoneVerified: true,
  role: 'STUDENT',
);

final _dashboard = ProfileDashboardData(
  gamification: const GamificationProfile(
    totalXp: 5630,
    currentStreak: 7,
    highestStreak: 12,
    xpToNext: 370,
    currentTier: 'LEGEND',
  ),
  achievements: List.generate(
    3,
    (index) => ProfileAchievement(
      id: 'achievement-$index',
      name: 'Achievement $index',
      description: '',
      // Only two of the three are earned, so the count is not just the length.
      earned: index < 2,
      progress: 1,
      progressMax: 1,
      progressPercent: 100,
      rarity: 'COMMON',
      xpReward: 10,
    ),
  ),
  activities: const [],
);

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(_user);
}

class _SignedOutAuth extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

Widget _app({required bool signedIn, GoRouter? router}) {
  final config =
      router ??
      GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(
              drawer: RiksaProfileDrawer(),
              body: SizedBox.shrink(),
            ),
          ),
        ],
      );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        signedIn ? _SignedInAuth.new : _SignedOutAuth.new,
      ),
      profileDashboardProvider.overrideWith((ref) async => _dashboard),
    ],
    child: MaterialApp.router(
      routerConfig: config,
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  // The drawer reads the locally stored avatar path through SharedPreferences,
  // which has no platform implementation under flutter test.
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('shows the learner identity and their own counts', (
    tester,
  ) async {
    await tester.pumpWidget(_app(signedIn: true));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(find.text('Sokha Chan'), findsOneWidget);
    expect(find.text('@sokha'), findsOneWidget);

    // The slot X gives Following/Followers carries the learner's own work.
    expect(find.text('5,630'), findsOneWidget);
    expect(find.text('Total XP'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-frame-legend')), findsOneWidget);

    // No follow graph exists, so nothing may imply one.
    expect(find.textContaining('Follow'), findsNothing);
    expect(find.textContaining('Followers'), findsNothing);
  });

  testWidgets('navigates and closes itself behind the destination', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            drawer: RiksaProfileDrawer(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/progress',
          builder: (_, _) => const Scaffold(body: Text('progress screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(signedIn: true, router: router));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    await tester.tap(find.byKey(const ValueKey('drawer-progress')));
    await tester.pumpAndSettle();

    expect(find.text('progress screen'), findsOneWidget);
    // Popping the drawer before pushing is what stops the learner returning
    // home onto an open menu.
    expect(find.byType(RiksaProfileDrawer), findsNothing);
  });

  testWidgets('navigates to saved lessons from drawer item', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            drawer: RiksaProfileDrawer(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/learn/saved',
          builder: (_, _) => const Scaffold(body: Text('saved lessons screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(signedIn: true, router: router));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    final savedItem = find.byKey(const ValueKey('drawer-saved-lessons'));
    expect(savedItem, findsOneWidget);
    await tester.ensureVisible(savedItem);
    await tester.pumpAndSettle();
    await tester.tap(savedItem);
    await tester.pumpAndSettle();

    expect(find.text('saved lessons screen'), findsOneWidget);
    expect(find.byType(RiksaProfileDrawer), findsNothing);
  });

  testWidgets('keeps community posts and blog articles separate', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            drawer: RiksaProfileDrawer(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('community posts')),
        ),
        GoRoute(
          path: '/blog/my-posts',
          builder: (_, _) => const Scaffold(body: Text('blog articles')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(signedIn: true, router: router));
    await tester.pumpAndSettle();
    await _openDrawer(tester);
    await tester.tap(find.byKey(const ValueKey('drawer-my-posts')));
    await tester.pumpAndSettle();
    expect(find.text('community posts'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    await _openDrawer(tester);
    await tester.tap(find.byKey(const ValueKey('drawer-my-articles')));
    await tester.pumpAndSettle();
    expect(find.text('blog articles'), findsOneWidget);
  });

  testWidgets('offers no account actions when signed out', (tester) async {
    await tester.pumpWidget(_app(signedIn: false));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(find.text('Sokha Chan'), findsNothing);
    expect(find.byKey(const ValueKey('drawer-logout')), findsNothing);
    expect(find.byKey(const ValueKey('drawer-counts')), findsNothing);
    // Navigation is still offered: signing in is reachable from those screens.
    expect(find.byKey(const ValueKey('drawer-progress')), findsOneWidget);
  });

  testWidgets('provides quick theme and language controls in drawer footer', (
    tester,
  ) async {
    await tester.pumpWidget(_app(signedIn: true));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    final themeToggle = find.byKey(const ValueKey('drawer-theme-toggle'));
    expect(themeToggle, findsOneWidget);
    await tester.tap(themeToggle);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageToggle), findsOneWidget);
  });
}
