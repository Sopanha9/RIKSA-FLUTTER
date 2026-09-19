import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_shell.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// Mirrors the shape the real router gives its branches: branch 0 holds screens
/// as flat siblings of the tab root, branch 1 nests them underneath it. The tab
/// bar has to read both the same way.
GoRouter _router(String initialLocation) {
  Widget screen(BuildContext context, GoRouterState state) =>
      Scaffold(body: Text(state.uri.path));

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: screen),
              GoRoute(path: '/communities', builder: screen),
              GoRoute(path: '/progress', builder: screen),
              GoRoute(path: '/community/posts/:id', builder: screen),
              GoRoute(path: '/blog', builder: screen),
              GoRoute(path: '/blog/:id', builder: screen),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: screen,
                routes: [
                  GoRoute(path: 'roadmap/:categoryId', builder: screen),
                  GoRoute(path: ':id', builder: screen),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: screen)],
          ),
        ],
      ),
    ],
  );
}

final _tabs = find.byKey(const ValueKey('persistent-bottom-navigation'));

Future<GoRouter> _pumpShell(WidgetTester tester, String initialLocation) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = _router(initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
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
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('the tabs stay on the screen a tab lands on', (tester) async {
    final router = await _pumpShell(tester, '/home');
    expect(_tabs, findsOneWidget);

    // A deep link straight to another tab root is still a destination: nothing
    // was pushed, so there is no back arrow and the tabs are the way out.
    router.go('/profile');
    await tester.pumpAndSettle();
    expect(_tabs, findsOneWidget);
  });

  testWidgets('the tabs step aside for anything pushed on top of a tab', (
    tester,
  ) async {
    // Each of these draws a back control of its own, so the tabs would be a
    // second way out of a screen that already has one — and on the post detail
    // they land on top of the comment composer.
    for (final pushed in [
      '/community/posts/post-1',
      '/communities',
      '/progress',
      '/blog',
      '/blog/article-1',
    ]) {
      final router = await _pumpShell(tester, '/home');
      expect(_tabs, findsOneWidget, reason: pushed);

      router.push(pushed);
      await tester.pumpAndSettle();
      expect(_tabs, findsNothing, reason: pushed);
    }
  });

  testWidgets('a nested branch reads the same way as a flat one', (
    tester,
  ) async {
    final router = await _pumpShell(tester, '/learn');
    expect(_tabs, findsOneWidget);

    router.push('/learn/roadmap/physics');
    await tester.pumpAndSettle();
    expect(_tabs, findsNothing);

    router.push('/learn/lesson-1');
    await tester.pumpAndSettle();
    expect(_tabs, findsNothing);
  });

  testWidgets('the tabs come back once the pushed screen is gone', (
    tester,
  ) async {
    final router = await _pumpShell(tester, '/home');

    router.push('/community/posts/post-1');
    await tester.pumpAndSettle();
    expect(_tabs, findsNothing);

    router.pop();
    await tester.pumpAndSettle();
    expect(_tabs, findsOneWidget);
  });

  testWidgets('switching tabs from a pushed screen restores the tabs', (
    tester,
  ) async {
    // The tab a learner left is still holding its pushed screen, so the branch
    // the shell reads has to be the one now on top, not the one it started in.
    final router = await _pumpShell(tester, '/home');

    router.push('/community/posts/post-1');
    await tester.pumpAndSettle();
    expect(_tabs, findsNothing);

    router.go('/profile');
    await tester.pumpAndSettle();
    expect(_tabs, findsOneWidget);
  });
}
