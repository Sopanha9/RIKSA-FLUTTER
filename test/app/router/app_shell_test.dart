import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_shell.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('keeps one bottom bar and preserves branch state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            _branch('/home', 'Home'),
            _branch('/learn', 'Learn'),
            _branch('/ai', 'AI'),
            _branch('/leaderboard', 'Leaderboard'),
            _branch('/profile', 'Profile'),
          ],
        ),
      ],
    );
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

    final persistentNavigation = find.byKey(
      const ValueKey('persistent-bottom-navigation'),
    );
    expect(persistentNavigation, findsOneWidget);
    expect(
      tester
          .widget<Scaffold>(find.byKey(const ValueKey('main-app-shell')))
          .extendBody,
      isTrue,
    );
    final navigationElement = tester.element(persistentNavigation);

    await tester.tap(find.byKey(const ValueKey('increment-Home')));
    await tester.pump();
    expect(find.text('Home 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-1')));
    await tester.pumpAndSettle();
    expect(find.text('Learn 0'), findsOneWidget);
    expect(
      identical(navigationElement, tester.element(persistentNavigation)),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
    await tester.pumpAndSettle();
    expect(find.text('Home 1'), findsOneWidget);
    expect(persistentNavigation, findsOneWidget);

    final navigationMorph = find.byKey(const ValueKey('bottom-nav-morph'));
    expect(tester.getSize(navigationMorph).width, greaterThan(300));

    await tester.drag(
      find.byKey(const ValueKey('scroll-Home')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(navigationMorph).width, 58);

    await tester.drag(
      find.byKey(const ValueKey('scroll-Home')),
      const Offset(0, 260),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(navigationMorph).width, greaterThan(300));
  });
}

StatefulShellBranch _branch(String path, String label) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => _StatefulTab(label: label),
      ),
    ],
  );
}

class _StatefulTab extends StatefulWidget {
  const _StatefulTab({required this.label});

  final String label;

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        key: ValueKey('scroll-${widget.label}'),
        padding: const EdgeInsets.only(top: 280),
        children: [
          Center(
            child: FilledButton(
              key: ValueKey('increment-${widget.label}'),
              onPressed: () => setState(() => _count += 1),
              child: Text('${widget.label} $_count'),
            ),
          ),
          const SizedBox(height: 900),
        ],
      ),
    );
  }
}
