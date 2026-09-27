import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/market/presentation/market_screen.dart';
import 'package:riksa_app/features/market/presentation/wardrobe_screen.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import '../market_test_support.dart';
import '../../../visuals/golden_fonts.dart';

void main() {
  setUpAll(loadRiksaGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets('buddy market ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(393, 1120);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
                rarity: 'RARE',
              ),
            ],
          ),
          BuddyItemSlot.eyewear: testMarketPage(
            slot: BuddyItemSlot.eyewear,
            items: [
              testMarketItem(
                id: 'round-glasses',
                slot: BuddyItemSlot.eyewear,
                name: 'Round glasses',
                assetKey: 'glasses_round',
                price: 240,
              ),
            ],
          ),
        },
      );
      await tester.pumpWidget(_app(const MarketScreen(), api, dark: dark));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Straw hat').first);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MarketScreen),
        matchesGoldenFile('goldens/market_en_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }

  testWidgets('buddy wardrobe', (tester) async {
    tester.view.physicalSize = const Size(393, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeMarketApi(
      pages: {
        BuddyItemSlot.hat: testMarketPage(
          items: [
            testMarketItem(owned: true, equipped: true),
            testMarketItem(
              id: 'sunny-cap',
              name: 'Sunny cap',
              assetKey: 'hat_sunny',
              price: 520,
              rarity: 'RARE',
              owned: true,
            ),
          ],
        ),
        BuddyItemSlot.eyewear: testMarketPage(
          slot: BuddyItemSlot.eyewear,
          items: [
            testMarketItem(
              id: 'round-glasses',
              slot: BuddyItemSlot.eyewear,
              name: 'Round glasses',
              assetKey: 'glasses_round',
              owned: true,
            ),
          ],
        ),
      },
    );
    await tester.pumpWidget(_app(const WardrobeScreen(), api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Straw hat').first);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(WardrobeScreen),
      matchesGoldenFile('goldens/wardrobe_en_light.png'),
    );
  });
}

Widget _app(Widget home, FakeMarketApi api, {bool dark = false}) =>
    ProviderScope(
      overrides: marketTestOverrides(api: api),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: home,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
