import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/market/providers/market_provider.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';

import 'market_test_support.dart';

void main() {
  test('provider requests the selected slot for a signed-in learner', () async {
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
              assetKey: 'glasses_round',
            ),
          ],
        ),
      },
    );
    final container = ProviderContainer(
      overrides: marketTestOverrides(api: api),
    );
    addTearDown(container.dispose);

    final page = await container.read(
      marketItemsProvider(BuddyItemSlot.eyewear).future,
    );

    expect(api.listCalls, [BuddyItemSlot.eyewear]);
    expect(page.items.single.name, 'Round glasses');
  });

  test(
    'guest catalog is browsable and does not disclose sample balance',
    () async {
      final api = FakeMarketApi();
      final container = ProviderContainer(
        overrides: marketTestOverrides(api: api, signedIn: false),
      );
      addTearDown(container.dispose);

      final page = await container.read(
        marketItemsProvider(BuddyItemSlot.hat).future,
      );

      expect(page.items, isNotEmpty);
      expect(page.balance, 0);
      expect(api.listCalls, isEmpty);
    },
  );

  test(
    'successful purchase refreshes the slot and marks the item owned',
    () async {
      final item = testMarketItem();
      final api = FakeMarketApi(
        pages: {
          BuddyItemSlot.hat: testMarketPage(items: [item]),
          BuddyItemSlot.eyewear: testMarketPage(
            slot: BuddyItemSlot.eyewear,
            items: const [],
          ),
        },
      );
      final container = ProviderContainer(
        overrides: marketTestOverrides(api: api),
      );
      addTearDown(container.dispose);
      await container.read(marketItemsProvider(BuddyItemSlot.hat).future);
      final key = container
          .read(marketPurchaseProvider)
          .beginPurchaseAttempt(item);

      final receipt = await container
          .read(marketPurchaseProvider)
          .purchase(item, idempotencyKey: key);
      final updated = await container.read(
        marketItemsProvider(BuddyItemSlot.hat).future,
      );

      expect(receipt.balance, 940);
      expect(updated.balance, 940);
      expect(updated.items.single.owned, isTrue);
      expect(api.purchaseCalls, 1);
      expect(api.purchaseKeys, [key]);
    },
  );

  test('network retry reuses the purchase attempt key', () async {
    final item = testMarketItem();
    final api = FakeMarketApi(pages: {BuddyItemSlot.hat: testMarketPage()})
      ..nextPurchaseError = StateError('network down');
    final container = ProviderContainer(
      overrides: marketTestOverrides(api: api),
    );
    addTearDown(container.dispose);
    final key = container
        .read(marketPurchaseProvider)
        .beginPurchaseAttempt(item);
    final service = container.read(marketPurchaseProvider);

    await expectLater(
      service.purchase(item, idempotencyKey: key),
      throwsA(isA<StateError>()),
    );
    await service.purchase(item, idempotencyKey: key);

    expect(api.purchaseCalls, 2);
    expect(api.purchaseKeys, [key, key]);
  });

  test('a new purchase sheet starts a fresh UUID key', () {
    final container = ProviderContainer(overrides: marketTestOverrides());
    addTearDown(container.dispose);
    final service = container.read(marketPurchaseProvider);
    final item = testMarketItem();

    final first = service.beginPurchaseAttempt(item);
    final second = service.beginPurchaseAttempt(item);

    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(second, isNot(first));
  });
}
