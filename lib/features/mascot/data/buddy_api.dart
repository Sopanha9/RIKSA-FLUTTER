import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/buddy_care.dart';
import '../domain/mascot.dart';

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
  });

  final BuddyCare care;
  final MascotSpecies species;
  final String name;
  final List<BuddyTodayAction> today;

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
    return BuddyMe(
      care: care,
      species: species,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : MascotProfileName.defaultName(species),
      today: today,
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
    return BuddyMe.fromJson(Map<String, dynamic>.from(response.data as Map));
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
    return BuddyMe.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> readComplete(String blogId) async {
    await _client.dio.post('/blog/$blogId/read-complete');
  }
}
