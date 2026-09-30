import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:riksa_app/features/market/providers/market_provider.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/market/data/market_api.dart';
import 'package:riksa_app/features/market/data/market_models.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/providers/buddy_care_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';

class MarketTestAuthNotifier extends AuthNotifier {
  MarketTestAuthNotifier({this.signedIn = true});

  final bool signedIn;

  @override
  AuthState build() => signedIn
      ? const Authenticated(
          AuthUser(
            id: 'market-test-user',
            username: 'learner',
            displayName: 'Learner',
            emailVerified: true,
            phoneVerified: false,
            role: 'USER',
          ),
        )
      : const Unauthenticated();
}

class MarketTestBuddyNotifier extends BuddyCareNotifier {
  static int equipCallCount = 0;

  @override
  BuddyCareState build() => BuddyCareState.initial(DateTime.utc(2026, 1, 1));

  @override
  Future<void> refresh() async {}

  @override
  Future<void> equip(
    BuddyItemSlot slot,
    String? itemId, {
    String? assetKey,
  }) async {
    equipCallCount++;
    final equipped = Map<BuddyItemSlot, BuddyEquipped>.of(state.equipped);
    if (itemId == null) {
      equipped.remove(slot);
    } else {
      equipped[slot] = BuddyEquipped(
        slot: slot,
        itemId: itemId,
        assetKey: assetKey ?? '',
      );
    }
    state = state.copyWith(equipped: Map.unmodifiable(equipped));
  }
}

class FakeMarketApi implements MarketApi {
  FakeMarketApi({Map<BuddyItemSlot, MarketItemsPage>? pages})
    : pages =
          pages ??
          {
            for (final slot in BuddyItemSlot.values)
              slot: marketPreviewPage(slot),
          };

  final Map<BuddyItemSlot, MarketItemsPage> pages;
  final List<BuddyItemSlot> listCalls = [];
  final List<String> purchaseKeys = [];
  final List<String> purchaseItemIds = [];
  Object? nextPurchaseError;
  Completer<MarketPurchaseReceipt>? purchaseGate;
  int purchaseCalls = 0;

  @override
  Future<MarketItemsPage> items(BuddyItemSlot slot) async {
    listCalls.add(slot);
    return pages[slot]!;
  }

  @override
  Future<MarketPurchaseReceipt> purchase(
    String itemId, {
    required String idempotencyKey,
  }) async {
    purchaseCalls++;
    purchaseKeys.add(idempotencyKey);
    purchaseItemIds.add(itemId);
    if (purchaseGate != null) return purchaseGate!.future;
    final error = nextPurchaseError;
    nextPurchaseError = null;
    if (error != null) throw error;

    final slot = pages.entries
        .firstWhere(
          (entry) => entry.value.items.any((item) => item.id == itemId),
        )
        .key;
    final page = pages[slot]!;
    final item = page.items.firstWhere((item) => item.id == itemId);
    final owned = MarketItem(
      id: item.id,
      slot: item.slot,
      name: item.name,
      nameKm: item.nameKm,
      price: item.price,
      rarity: item.rarity,
      assetKey: item.assetKey,
      owned: true,
      equipped: item.equipped,
      locked: item.locked,
      lockReason: item.lockReason,
      availableUntil: item.availableUntil,
    );
    pages[slot] = MarketItemsPage(
      balance: page.balance - item.price,
      items: [
        for (final existing in page.items)
          if (existing.id == itemId) owned else existing,
      ],
    );
    return MarketPurchaseReceipt(
      item: owned,
      balance: page.balance - item.price,
    );
  }
}

MarketItem testMarketItem({
  String id = 'straw-hat',
  BuddyItemSlot slot = BuddyItemSlot.hat,
  String name = 'Straw hat',
  String nameKm = 'មួកចំបើង',
  int price = 300,
  String rarity = 'COMMON',
  String assetKey = 'hat_straw',
  bool owned = false,
  bool equipped = false,
  bool locked = false,
  String? lockReason,
  DateTime? availableUntil,
}) => MarketItem(
  id: id,
  slot: slot,
  name: name,
  nameKm: nameKm,
  price: price,
  rarity: rarity,
  assetKey: assetKey,
  owned: owned,
  equipped: equipped,
  locked: locked,
  lockReason: lockReason,
  availableUntil: availableUntil,
);

MarketItemsPage testMarketPage({
  BuddyItemSlot slot = BuddyItemSlot.hat,
  int balance = 1240,
  List<MarketItem>? items,
}) => MarketItemsPage(
  balance: balance,
  items: items ?? [testMarketItem(slot: slot)],
);

List<Override> marketTestOverrides({
  FakeMarketApi? api,
  bool signedIn = true,
  Map<BuddyItemSlot, MarketItemsPage>? pages,
}) => [
  authProvider.overrideWith(() => MarketTestAuthNotifier(signedIn: signedIn)),
  buddyCareProvider.overrideWith(MarketTestBuddyNotifier.new),
  marketApiProvider.overrideWithValue(api ?? FakeMarketApi(pages: pages)),
  profileDashboardProvider.overrideWith(
    (ref) async => const ProfileDashboardData(
      gamification: GamificationProfile(
        totalXp: 1200,
        xpBalance: 1240,
        currentStreak: 3,
        highestStreak: 4,
        xpToNext: 0,
      ),
      achievements: [],
      activities: [],
    ),
  ),
];
