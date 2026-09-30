import '../../mascot/data/buddy_api.dart';

class MarketItem {
  const MarketItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.nameKm,
    required this.price,
    required this.rarity,
    required this.assetKey,
    required this.owned,
    required this.equipped,
    required this.locked,
    this.lockReason,
    this.availableUntil,
  });

  final String id;
  final BuddyItemSlot slot;
  final String name;
  final String nameKm;
  final int price;
  final String rarity;
  final String assetKey;
  final bool owned;
  final bool equipped;
  final bool locked;
  final String? lockReason;
  final DateTime? availableUntil;

  factory MarketItem.fromJson(Map<String, dynamic> json) {
    final slot = BuddyItemSlot.fromApiName(json['slot']);
    if (slot == null) throw const FormatException('Unknown market item slot.');
    return MarketItem(
      id: json['id']?.toString() ?? '',
      slot: slot,
      name: json['name']?.toString() ?? '',
      nameKm: json['nameKm']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      rarity: json['rarity']?.toString().toUpperCase() ?? 'COMMON',
      assetKey: json['assetKey']?.toString() ?? '',
      owned: json['owned'] == true,
      equipped: json['equipped'] == true,
      locked: json['locked'] == true,
      lockReason: json['lockReason']?.toString(),
      availableUntil: DateTime.tryParse(
        json['availableUntil']?.toString() ?? '',
      ),
    );
  }
}

class MarketItemsPage {
  const MarketItemsPage({required this.balance, required this.items});

  final int balance;
  final List<MarketItem> items;

  factory MarketItemsPage.fromJson(Map<String, dynamic> json) =>
      MarketItemsPage(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => MarketItem.fromJson(item.cast<String, dynamic>()))
            .toList(growable: false),
      );
}

class MarketPurchaseReceipt {
  const MarketPurchaseReceipt({required this.item, required this.balance});

  final MarketItem item;
  final int balance;

  factory MarketPurchaseReceipt.fromJson(Map<String, dynamic> json) =>
      MarketPurchaseReceipt(
        item: MarketItem.fromJson(
          (json['item'] as Map).cast<String, dynamic>(),
        ),
        balance: (json['balance'] as num?)?.toInt() ?? 0,
      );
}

/// Preview items let signed-out learners browse the catalog without exposing
/// a guessed spendable balance or enabling purchases.
MarketItemsPage marketPreviewPage(BuddyItemSlot slot) => MarketItemsPage(
  balance: 0,
  items: switch (slot) {
    BuddyItemSlot.hat => const [
      MarketItem(
        id: 'preview-straw-hat',
        slot: BuddyItemSlot.hat,
        name: 'Straw hat',
        nameKm: 'មួកចំបើង',
        price: 300,
        rarity: 'COMMON',
        assetKey: 'hat_straw',
        owned: false,
        equipped: false,
        locked: false,
      ),
      MarketItem(
        id: 'preview-sun-hat',
        slot: BuddyItemSlot.hat,
        name: 'Sunny cap',
        nameKm: 'មួកថ្ងៃរះ',
        price: 520,
        rarity: 'RARE',
        assetKey: 'hat_sunny',
        owned: false,
        equipped: false,
        locked: false,
      ),
    ],
    BuddyItemSlot.eyewear => const [
      MarketItem(
        id: 'preview-round-glasses',
        slot: BuddyItemSlot.eyewear,
        name: 'Round glasses',
        nameKm: 'វ៉ែនតាមូល',
        price: 240,
        rarity: 'COMMON',
        assetKey: 'glasses_round',
        owned: false,
        equipped: false,
        locked: false,
      ),
      MarketItem(
        id: 'preview-star-glasses',
        slot: BuddyItemSlot.eyewear,
        name: 'Star glasses',
        nameKm: 'វ៉ែនតាផ្កាយ',
        price: 650,
        rarity: 'EPIC',
        assetKey: 'glasses_star',
        owned: false,
        equipped: false,
        locked: false,
      ),
    ],
  },
);
