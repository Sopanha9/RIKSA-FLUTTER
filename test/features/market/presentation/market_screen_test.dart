import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/market/data/market_models.dart';
import 'package:riksa_app/features/market/presentation/market_screen.dart';
import 'package:riksa_app/features/market/presentation/wardrobe_screen.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_look.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import '../market_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping an item tries it on without equipping or purchasing', (
    tester,
  ) async {
    MarketTestBuddyNotifier.equipCallCount = 0;
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(
          items: [
            testMarketItem(),
            testMarketItem(
              id: 'sunny-cap',
              name: 'Sunny cap',
              assetKey: 'hat_sunny',
              price: 520,
            ),
          ],
        ),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: const [],
        ),
      },
    );

    await tester.pumpWidget(_app(api: api));
    await tester.pumpAndSettle();
    final apiCallsBeforeTryOn = api.listCalls.length;
    await tester.ensureVisible(find.text('Straw hat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Straw hat').first);
    await tester.pumpAndSettle();

    expect(api.listCalls, hasLength(apiCallsBeforeTryOn));
    expect(api.purchaseCalls, 0);
    expect(MarketTestBuddyNotifier.equipCallCount, 0);
    expect(find.byType(BuddyLook), findsWidgets);
    expect(find.text('Buy for 300 XP'), findsOneWidget);
  });

  testWidgets(
    'buy confirmation ignores a double tap while request is pending',
    (tester) async {
      final api = FakeMarketApi(pages: {BuddyItemSlot.hat: testMarketPage()});
      final gate = Completer<MarketPurchaseReceipt>();
      api.purchaseGate = gate;
      await tester.pumpWidget(_app(api: api));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Straw hat').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Straw hat').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buy for 300 XP'));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const ValueKey('market-confirm-purchase'));
      await tester.tap(confirm);
      await tester.pump();
      await tester.tap(confirm, warnIfMissed: false);
      await tester.pump();
      expect(api.purchaseCalls, 1);

      final item = testMarketItem(owned: true);
      gate.complete(MarketPurchaseReceipt(item: item, balance: 940));
      await tester.pumpAndSettle();
      expect(find.text('You got Straw hat!'), findsOneWidget);
      expect(find.text('Wear it now'), findsOneWidget);
    },
  );

  testWidgets('guest can browse but buying opens the require-account route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/market',
      routes: [
        GoRoute(
          path: '/market',
          builder: (context, state) => const MarketScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Sign in page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _app(signedIn: false, router: router, api: FakeMarketApi()),
    );
    await tester.pumpAndSettle();
    expect(find.text('XP 0 to spend'), findsNothing);
    await tester.ensureVisible(find.text('Straw hat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Straw hat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy for 300 XP'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in page'), findsOneWidget);
  });

  testWidgets('shows the precise shortfall for insufficient XP', (
    tester,
  ) async {
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(balance: 240),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: const [],
        ),
      },
    );
    await tester.pumpWidget(_app(api: api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Straw hat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Straw hat').first);
    await tester.pumpAndSettle();

    expect(find.text('Not enough XP (need 60 more)'), findsOneWidget);
    expect(find.text('Spending XP never lowers your rank.'), findsOneWidget);
  });

  testWidgets('Khmer market fits at 200 percent text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: [
            testMarketItem(
              id: 'round-glasses',
              slot: BuddyItemSlot.eyewear,
              name: 'Round glasses',
              nameKm: 'វ៉ែនតាមូល',
              assetKey: 'glasses_round',
            ),
          ],
        ),
      },
    );
    await tester.pumpWidget(
      _app(api: api, locale: const Locale('km'), textScale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('វ៉ែនតា'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer wardrobe fits at 200 percent text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(
          items: [testMarketItem(owned: true, equipped: true)],
        ),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: [
            testMarketItem(
              id: 'round-glasses',
              slot: BuddyItemSlot.eyewear,
              name: 'Round glasses',
              nameKm: 'វ៉ែនតាមូល',
              assetKey: 'glasses_round',
              owned: true,
            ),
          ],
        ),
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: marketTestOverrides(api: api),
        child: MaterialApp(
          home: const WardrobeScreen(),
          locale: const Locale('km'),
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('wardrobe equips and unequips an owned item', (tester) async {
    MarketTestBuddyNotifier.equipCallCount = 0;
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(items: [testMarketItem(owned: true)]),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: const [],
        ),
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: marketTestOverrides(api: api),
        child: MaterialApp(
          home: const WardrobeScreen(),
          theme: AppTheme.light,
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

    await tester.tap(find.text('Equip'));
    await tester.pumpAndSettle();
    expect(MarketTestBuddyNotifier.equipCallCount, 1);
    expect(find.text('Take off'), findsOneWidget);

    await tester.tap(find.text('Take off'));
    await tester.pumpAndSettle();
    expect(MarketTestBuddyNotifier.equipCallCount, 2);
    expect(find.text('Equip'), findsOneWidget);
  });
}

Widget _app({
  required FakeMarketApi api,
  bool signedIn = true,
  Locale locale = const Locale('en'),
  double textScale = 1,
  GoRouter? router,
}) => ProviderScope(
  overrides: marketTestOverrides(api: api, signedIn: signedIn),
  child: MaterialApp.router(
    routerConfig:
        router ??
        GoRouter(
          initialLocation: '/market',
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const MarketScreen(),
            ),
          ],
        ),
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
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
  ),
);
