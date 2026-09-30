import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/buddy_care.dart';
import '../domain/mascot.dart';

enum BuddyItemSlot {
  hat('HAT'),
  eyewear('EYEWEAR');

  const BuddyItemSlot(this.apiName);

  final String apiName;

  static BuddyItemSlot? fromApiName(Object? value) {
    final name = value?.toString().toUpperCase();
    return BuddyItemSlot.values
        .where((slot) => slot.apiName == name)
        .firstOrNull;
  }
}

@immutable
class BuddyEquipped {
  const BuddyEquipped({
    required this.slot,
    required this.itemId,
    required this.assetKey,
  });

  final BuddyItemSlot slot;
  final String itemId;
  final String assetKey;

  factory BuddyEquipped.fromJson(
    BuddyItemSlot slot,
    Map<String, dynamic> json,
  ) => BuddyEquipped(
    slot: slot,
    itemId: json['itemId']?.toString() ?? '',
    assetKey: json['assetKey']?.toString() ?? '',
  );

  Map<String, Object?> toJson() => {'itemId': itemId, 'assetKey': assetKey};
}

/// Public fields used to render another learner's buddy without private data.
@immutable
class PublicBuddyLook {
  const PublicBuddyLook({
    required this.species,
    required this.name,
    this.equipped = const {},
  });

  final MascotSpecies species;
  final String name;
  final Map<BuddyItemSlot, String> equipped;

  factory PublicBuddyLook.fromJson(Map<String, dynamic> json) {
    final speciesName = json['species']?.toString();
    final species =
        MascotSpecies.values
            .where((item) => item.name == speciesName)
            .firstOrNull ??
        MascotSpecies.crocodile;
    final rawEquipped = json['equipped'];
    final equipped = <BuddyItemSlot, String>{};
    if (rawEquipped is Map) {
      for (final entry in rawEquipped.entries) {
        final slot = BuddyItemSlot.fromApiName(entry.key);
        final value = entry.value;
        final assetKey = value is Map
            ? value['assetKey']?.toString()
            : value?.toString();
        if (slot != null && assetKey?.trim().isNotEmpty == true) {
          equipped[slot] = assetKey!.trim();
        }
      }
    }
    final name = json['name']?.toString().trim();
    return PublicBuddyLook(
      species: species,
      name: name?.isNotEmpty == true
          ? name!
          : MascotProfileName.defaultName(species),
      equipped: Map.unmodifiable(equipped),
    );
  }

  static PublicBuddyLook? fromNullable(Object? value) => value is Map
      ? PublicBuddyLook.fromJson(Map<String, dynamic>.from(value))
      : null;

  Map<String, Object?> toJson() => {
    'species': species.name,
    'name': name,
    'equipped': {
      for (final entry in equipped.entries) entry.key.apiName: entry.value,
    },
  };
}

final buddyApiProvider = Provider<BuddyApi>(
  (ref) => BuddyApi(ref.watch(dioClientProvider)),
);

@immutable
class BuddyTodayAction {
  const BuddyTodayAction({
    required this.key,
    required this.done,
    required this.count,
    required this.cap,
  });

  final String key;
  final bool done;
  final int count;
  final int? cap;

  factory BuddyTodayAction.fromJson(Map<String, dynamic> json) =>
      BuddyTodayAction(
        key: json['key']?.toString() ?? '',
        done: json['done'] == true,
        count: (json['count'] as num?)?.toInt() ?? 0,
        cap: (json['cap'] as num?)?.toInt(),
      );
}

@immutable
class BuddyMe {
  const BuddyMe({
    required this.care,
    required this.species,
    required this.name,
    required this.today,
    this.equipped = const {},
    this.balance,
    this.chosen = true,
  });

  final BuddyCare care;
  final MascotSpecies species;
  final String name;
  final List<BuddyTodayAction> today;
  final Map<BuddyItemSlot, BuddyEquipped> equipped;
  final int? balance;

  /// Old servers omitted this flag; they are treated as already chosen.
  final bool chosen;

  Map<String, Object?> toJson() => {
    ...care.toJson(),
    'species': species.name,
    'name': name,
    'today': [
      for (final item in today)
        {
          'key': item.key,
          'done': item.done,
          'count': item.count,
          'cap': item.cap,
        },
    ],
    'equipped': {
      for (final entry in equipped.entries)
        entry.key.apiName: entry.value.toJson(),
    },
    'balance': balance,
    'chosen': chosen,
  };

  factory BuddyMe.fromJson(Map<String, dynamic> json) {
    final speciesName = json['species']?.toString();
    final species =
        MascotSpecies.values
            .where((item) => item.name == speciesName)
            .firstOrNull ??
        MascotSpecies.crocodile;
    final counts = <BuddyCareSource, int>{};
    final today = (json['today'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => BuddyTodayAction.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    for (final item in today) {
      final source = BuddyCareSource.fromKey(item.key);
      if (source != null) counts[source] = item.count;
    }
    final now = DateTime.now();
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    final care = BuddyCare(
      energy: (json['energy'] as num?)?.toInt().clamp(0, 100).toInt() ?? 60,
      bond: (json['bond'] as num?)?.toInt().clamp(0, 0x7fffffff).toInt() ?? 0,
      updatedAt: updatedAt ?? now,
      careDay: phnomPenhCareDay(now),
      dailyCounts: counts,
      lessonBondAwardsToday: (counts[BuddyCareSource.lesson] ?? 0)
          .clamp(0, 5)
          .toInt(),
    ).settle(now);
    final equipped = <BuddyItemSlot, BuddyEquipped>{};
    final rawEquipped = json['equipped'];
    if (rawEquipped is Map) {
      for (final entry in rawEquipped.entries) {
        final slot = BuddyItemSlot.fromApiName(entry.key);
        if (slot != null && entry.value is Map) {
          equipped[slot] = BuddyEquipped.fromJson(
            slot,
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    return BuddyMe(
      care: care,
      species: species,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : MascotProfileName.defaultName(species),
      today: today,
      equipped: Map.unmodifiable(equipped),
      balance: (json['balance'] as num?)?.toInt(),
      chosen: json['chosen'] is bool ? json['chosen'] as bool : true,
    );
  }
}

/// Name fallback kept here to avoid coupling the API DTO to provider state.
abstract final class MascotProfileName {
  static String defaultName(MascotSpecies species) => switch (species) {
    MascotSpecies.crocodile => 'Croco',
    MascotSpecies.capybara => 'Capy',
  };
}

class BuddyApi {
  BuddyApi(this._client);

  final DioClient _client;

  Future<BuddyMe> getMe() async {
    final response = await _client.dio.get('/buddy/me');
    return BuddyMe.fromJson(jsonMap(response));
  }

  Future<BuddyMe> updateMe({
    MascotSpecies? species,
    String? name,
    int? guestEnergy,
    int? guestBond,
  }) async {
    final data = <String, Object?>{};
    if (species != null) data['species'] = species.name;
    if (name != null) data['name'] = name;
    if (guestEnergy != null) data['guestEnergy'] = guestEnergy;
    if (guestBond != null) data['guestBond'] = guestBond;
    final response = await _client.dio.put('/buddy/me', data: data);
    return BuddyMe.fromJson(jsonMap(response));
  }

  Future<BuddyMe> equip(BuddyItemSlot slot, String? itemId) async {
    final response = await _client.dio.put(
      '/buddy/me/equipped',
      data: {'slot': slot.apiName, 'itemId': itemId},
    );
    return BuddyMe.fromJson(jsonMap(response));
  }

  Future<void> readComplete(String blogId) async {
    await _client.dio.post('/blog/$blogId/read-complete');
  }
}
