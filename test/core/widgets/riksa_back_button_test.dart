import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/widgets/riksa_back_button.dart';

void main() {
  testWidgets('pops to the previous page when one is on the stack', (
    tester,
  ) async {
    final router = _router('/home');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    router.push('/detail');
    await tester.pumpAndSettle();

    expect(find.text('/detail'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('back')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.text('/home'), findsOneWidget);
  });

  testWidgets('uses the fallback route when opened directly', (tester) async {
    final router = _router('/detail');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(router.canPop(), isFalse);
    await tester.tap(find.byKey(const ValueKey('back')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.text('/home'), findsOneWidget);
  });

  testWidgets('pops a plain Navigator route without a GoRouter', (
    tester,
  ) async {
    await tester.pumpWidget(_plainNavigatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-plain-detail')));
    await tester.pumpAndSettle();
    expect(find.text('plain-detail'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plain-back')));
    await tester.pumpAndSettle();

    expect(find.text('before-compose'), findsOneWidget);
    expect(find.text('plain-detail'), findsNothing);
  });
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const Scaffold(body: Text('/home')),
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: const RiksaBackButton(
            key: ValueKey('back'),
            fallbackLocation: '/home',
          ),
        ),
        body: const Text('/detail'),
      ),
    ),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
);

Widget _plainNavigatorApp() => MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  home: Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          const Text('before-compose'),
          TextButton(
            key: const ValueKey('open-plain-detail'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    leading: const RiksaBackButton(
                      key: ValueKey('plain-back'),
                      fallbackLocation: '/fallback',
                    ),
                  ),
                  body: const Text('plain-detail'),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ],
      ),
    ),
  ),
);
