import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../mascot/data/buddy_api.dart';
import '../../mascot/providers/buddy_care_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/market_api.dart';
import '../data/market_models.dart';

final marketApiProvider = Provider<MarketApi>(
  (ref) => MarketApi(ref.watch(dioClientProvider)),
);

final marketItemsProvider =
    FutureProvider.family<MarketItemsPage, BuddyItemSlot>((ref, slot) async {
      final userId = watchCurrentUserId(ref);
      if (userId == null) return marketPreviewPage(slot);
      return ref.watch(marketApiProvider).items(slot);
    });

/// Holds one idempotency key while the confirmation sheet is open. A failed
/// request can be retried with that key; a newly opened sheet starts a new
/// purchase attempt.
final marketPurchaseProvider = Provider<MarketPurchaseService>(
  (ref) => MarketPurchaseService(ref),
);

class MarketPurchaseService {
  MarketPurchaseService(this._ref);

  final Ref _ref;
  String? _pendingItemId;
  String? _pendingKey;

  String beginPurchaseAttempt(MarketItem item) {
    _pendingItemId = item.id;
    _pendingKey = _newUuidV4();
    return _pendingKey!;
  }

  Future<MarketPurchaseReceipt> purchase(
    MarketItem item, {
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ??
        (_pendingItemId == item.id ? _pendingKey : null) ??
        _newUuidV4();
    final receipt = await _ref
        .read(marketApiProvider)
        .purchase(item.id, idempotencyKey: key);
    if (_pendingItemId == item.id && _pendingKey == key) {
      _pendingItemId = null;
      _pendingKey = null;
    }
    _refreshAfterPurchase();
    return receipt;
  }

  void _refreshAfterPurchase() {
    for (final slot in BuddyItemSlot.values) {
      _ref.invalidate(marketItemsProvider(slot));
    }
    _ref.invalidate(profileDashboardProvider);
    unawaited(
      _ref.read(buddyCareProvider.notifier).refresh().catchError((Object _) {}),
    );
    // Invalidation refreshes listeners; reading these futures also starts a
    // fetch when the destination view is not currently mounted.
    for (final slot in BuddyItemSlot.values) {
      unawaited(
        _ref
            .read(marketItemsProvider(slot).future)
            .then<void>((_) {})
            .catchError((Object _) {}),
      );
    }
    unawaited(
      _ref
          .read(profileDashboardProvider.future)
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
  }
}

String _newUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
