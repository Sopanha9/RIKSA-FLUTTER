import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/leaderBoard/presentation/leaderboard_screen.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'current-user',
      username: 'sophea',
      displayName: 'Sok Sophea',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      provinceId: 'phnom-penh',
    ),
  );
}

void main() {
  testWidgets('keeps the signed-in learner rank inline above rankings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rows = List.generate(
      12,
      (index) => LeaderboardRow(
        rank: index + 1,
        userId: 'learner-$index',
        score: 2400 - (index * 100),
        rankingTier: index < 3 ? 'GOLD' : 'SILVER',
        displayName: 'Learner ${index + 1}',
      ),
    );

    final router = GoRouter(
      initialLocation: '/leaderboard',
      routes: [
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const Scaffold(
            extendBody: true,
            body: LeaderboardScreen(),
            bottomNavigationBar: SizedBox(
              key: ValueKey('test-bottom-navigation'),
              height: 94,
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthNotifier.new),
          profileRankProvider.overrideWith(
            (ref) async => const LeaderboardRank(
              countryRank: 10,
              countryScore: 1200,
              countryTier: 'SILVER',
              provinceRank: 4,
              provinceScore: 1200,
              provinceTier: 'GOLD',
            ),
          ),
          leaderboardProvider.overrideWith((ref, scope) async => rows),
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
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('current-user-rank-card'));
    final podium = find.byKey(const ValueKey('leaderboard-podium'));
    final rankings = find.byKey(const ValueKey('leaderboard-rankings-section'));
    expect(card, findsOneWidget);
    expect(find.text('Your rank'), findsOneWidget);
    expect(find.text('Province'), findsOneWidget);
    expect(find.text('phnom-penh'), findsNothing);
    expect(
      find.descendant(of: card, matching: find.text('#10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('1200 XP')),
      findsOneWidget,
    );

    final initialTop = tester.getTopLeft(card).dy;
    expect(tester.getBottomLeft(podium).dy, lessThan(initialTop));
    expect(
      tester.getBottomLeft(card).dy,
      lessThan(tester.getTopLeft(rankings).dy),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(card).dy, lessThan(initialTop));
    expect(
      find.descendant(of: card, matching: find.text('#10')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates the inline card for the province scope', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/leaderboard',
      routes: [
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthNotifier.new),
          profileRankProvider.overrideWith(
            (ref) async => const LeaderboardRank(
              countryRank: 10,
              countryScore: 1200,
              countryTier: 'SILVER',
              provinceRank: 4,
              provinceScore: 1200,
              provinceTier: 'GOLD',
            ),
          ),
          leaderboardProvider.overrideWith(
            (ref, scope) async => const <LeaderboardRow>[],
          ),
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Province'));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('current-user-rank-card'));
    expect(
      find.descendant(of: card, matching: find.text('#4')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('1200 XP')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
