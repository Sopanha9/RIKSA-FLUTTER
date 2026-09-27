import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/buddy_api.dart';
import '../domain/buddy_care.dart';
import '../domain/mascot.dart';
import 'mascot_provider.dart';

@immutable
class BuddyCareState {
  const BuddyCareState({
    required this.care,
    required this.species,
    required this.name,
    this.today = const [],
    this.userId,
    this.equipped = const {},
    this.balance,
    this.chosen = true,
    this.serverSynced = false,
  });

  factory BuddyCareState.initial(DateTime now) => BuddyCareState(
    care: BuddyCare.initial(now),
    species: MascotSpecies.crocodile,
    name: 'Croco',
  );

  final BuddyCare care;
  final MascotSpecies species;
  final String name;
  final List<BuddyTodayAction> today;
  final String? userId;
  final Map<BuddyItemSlot, BuddyEquipped> equipped;
  final int? balance;
  final bool chosen;
  final bool serverSynced;

  BuddyCareState copyWith({
    BuddyCare? care,
    MascotSpecies? species,
    String? name,
    List<BuddyTodayAction>? today,
    String? userId,
    Map<BuddyItemSlot, BuddyEquipped>? equipped,
    int? balance,
    bool? chosen,
    bool? serverSynced,
    bool clearUser = false,
  }) => BuddyCareState(
    care: care ?? this.care,
    species: species ?? this.species,
    name: name ?? this.name,
    today: today ?? this.today,
    userId: clearUser ? null : userId ?? this.userId,
    equipped: equipped ?? this.equipped,
    balance: balance ?? this.balance,
    chosen: chosen ?? this.chosen,
    serverSynced: serverSynced ?? this.serverSynced,
  );

  factory BuddyCareState.fromMe(
    BuddyMe me, {
    String? userId,
    bool serverSynced = true,
  }) => BuddyCareState(
    care: me.care,
    species: me.species,
    name: me.name,
    today: me.today,
    userId: userId,
    equipped: me.equipped,
    balance: me.balance,
    chosen: me.chosen,
    serverSynced: serverSynced,
  );
}

/// Restores a cached buddy immediately, then reconciles signed-in state with
/// the server. Guests keep lesson care on-device until they sign in.
class BuddyCareNotifier extends Notifier<BuddyCareState>
    with WidgetsBindingObserver {
  static const _guestKey = 'riksa_buddy_guest_care';
  static const _signedInKeyPrefix = 'riksa_buddy_care_user_';
  static const _guestSpeciesKey = 'riksa_mascot_species_guest';
  static const _guestNameKey = 'riksa_mascot_name_guest';

  String? _activeUserId;
  String? _syncingUserId;
  Future<void>? _syncOperation;
  final Map<BuddyItemSlot, int> _equipVersions = {};

  @override
  BuddyCareState build() {
    final now = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next case Authenticated(:final userId)) {
        if (userId != _activeUserId && userId != _syncingUserId) {
          unawaited(_syncSignedIn(userId));
        }
      } else if (_activeUserId != null || _syncingUserId != null) {
        _activeUserId = null;
        _syncingUserId = null;
        unawaited(_restoreGuest());
      }
    });
    ref.listen<MascotState>(mascotProvider, (previous, next) {
      final profile = next.profile;
      if (profile == null) return;
      final auth = ref.read(authProvider);
      final confirmedForSignedInUser =
          next.choiceConfirmedLocally &&
          auth is Authenticated &&
          _activeUserId == auth.userId;
      if (state.species == profile.species &&
          state.name == profile.name &&
          (!confirmedForSignedInUser || state.chosen)) {
        return;
      }
      state = state.copyWith(
        species: profile.species,
        name: profile.name,
        chosen: confirmedForSignedInUser ? true : null,
      );
      unawaited(_saveCurrentState());
    });
    final auth = ref.read(authProvider);
    if (auth case Authenticated(:final userId)) {
      unawaited(_syncSignedIn(userId));
    } else {
      unawaited(_restoreGuest());
    }
    return BuddyCareState.initial(now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final settled = this.state.care.settle(DateTime.now());
    this.state = this.state.copyWith(
      care: settled,
      today: _todayFromCare(settled),
    );
    unawaited(_saveCurrentState());
    if (_activeUserId != null) unawaited(refresh());
  }

  Future<void> _restoreGuest() async {
    final prefs = await _loadPreferences();
    if (prefs == null) return;
    try {
      final json = prefs.getString(_guestKey);
      final care = json == null
          ? BuddyCare.initial(DateTime.now())
          : BuddyCare.fromJson(
              Map<String, dynamic>.from(jsonDecode(json) as Map),
            );
      final profile =
          ref.read(mascotProvider).profile ??
          await _profileFromPreferences(prefs);
      if (_syncingUserId != null || _activeUserId != null) return;
      state = BuddyCareState(
        care: care,
        species: profile.species,
        name: profile.name,
        today: _todayFromCare(care),
      );
    } catch (_) {
      // Keep the initial buddy state if its local cache cannot be restored.
    }
  }

  Future<void> _syncSignedIn(String userId) {
    if (_activeUserId == userId) return Future<void>.value();
    if (_syncingUserId == userId && _syncOperation != null) {
      return _syncOperation!;
    }
    _syncingUserId = userId;
    final operation = _performSignedInSync(userId);
    _syncOperation = operation;
    return operation.whenComplete(() {
      if (_syncingUserId == userId) {
        _syncingUserId = null;
        _syncOperation = null;
      }
    });
  }

  Future<void> _performSignedInSync(String userId) async {
    final prefs = await _loadPreferences();
    final cacheKey = '$_signedInKeyPrefix$userId';
    String? cachedJson;
    if (prefs != null) {
      try {
        cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final cached = BuddyMe.fromJson(
            Map<String, dynamic>.from(jsonDecode(cachedJson) as Map),
          );
          _applyServerState(cached, userId, serverSynced: false);
        }
      } catch (_) {
        cachedJson = null;
      }
    }

    try {
      String? guestJson;
      try {
        guestJson = prefs?.getString(_guestKey);
      } catch (_) {
        // If the local guest cache is unavailable, still load the server buddy.
      }
      var remote = await ref.read(buddyApiProvider).getMe();
      final hasPendingGuestChoice =
          prefs != null &&
          ((prefs.getBool(MascotNotifier.guestChoicePendingKey) ?? false) ||
              prefs.getString('riksa_mascot_species_guest') != null);
      if (!remote.chosen && hasPendingGuestChoice) {
        BuddyCare? guestCare;
        try {
          if (guestJson != null) {
            guestCare = BuddyCare.fromJson(
              Map<String, dynamic>.from(jsonDecode(guestJson) as Map),
            );
          }
        } catch (_) {
          // A malformed care cache cannot suppress the guest buddy choice.
        }
        final profile = await _profileFromPreferences(prefs);
        remote = await ref
            .read(buddyApiProvider)
            .updateMe(
              species: profile.species,
              name: profile.name,
              guestEnergy: guestCare?.energy,
              guestBond: guestCare?.bond,
            );
      }
      if (hasPendingGuestChoice) {
        // A server buddy always wins. Once the account has loaded, clear the
        // guest choice so it cannot be replayed against another account.
        try {
          await prefs.remove(_guestKey);
          await prefs.remove(MascotNotifier.guestChoicePendingKey);
          await prefs.remove('riksa_mascot_species_guest');
          await prefs.remove('riksa_mascot_name_guest');
        } catch (_) {
          // Cleanup is best-effort after the server buddy has loaded.
        }
      }
      if (!ref.mounted || _syncingUserId != userId) return;
      _activeUserId = userId;
      try {
        await prefs?.setString(cacheKey, jsonEncode(remote.toJson()));
      } catch (_) {
        // The server response remains usable when its local cache cannot save.
      }
      _applyServerState(remote, userId, serverSynced: true);
    } catch (_) {
      if (cachedJson == null && ref.mounted) {
        _activeUserId = userId;
        state = state.copyWith(userId: userId, serverSynced: true);
      } else if (ref.mounted && _syncingUserId == userId) {
        // Keep a cached look visible and allow the app to continue offline.
        state = state.copyWith(serverSynced: true);
      }
    }
  }

  void _applyServerState(
    BuddyMe me,
    String userId, {
    required bool serverSynced,
  }) {
    _activeUserId = userId;
    state = BuddyCareState.fromMe(
      me,
      userId: userId,
      serverSynced: serverSynced,
    );
    unawaited(
      ref
          .read(mascotProvider.notifier)
          .acceptRemoteChoice(me.species, me.name, userId: userId),
    );
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    if (_activeUserId == null) {
      final auth = ref.read(authProvider);
      if (auth case Authenticated(:final userId)) {
        await _syncSignedIn(userId);
      }
    }
    final userId = _activeUserId;
    if (userId == null) return;
    try {
      final me = await ref.read(buddyApiProvider).getMe();
      if (!ref.mounted || _activeUserId != userId) return;
      _applyServerState(me, userId, serverSynced: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_signedInKeyPrefix$userId',
        jsonEncode(me.toJson()),
      );
    } catch (_) {
      // Keep the last cached state visible while offline.
    }
  }

  Future<void> recordLocalGain(
    BuddyCareSource source, {
    String? sourceId,
  }) async {
    final auth = ref.read(authProvider);
    if (auth case Authenticated(:final userId)) {
      if (_activeUserId == null) {
        if (_syncingUserId != userId) {
          unawaited(_syncSignedIn(userId));
        }
        _activeUserId = userId;
      }
    }
    final care = state.care.gain(source, DateTime.now(), sourceId: sourceId);
    state = state.copyWith(care: care, today: _todayFromCare(care));
    await _saveCurrentState();
    if (_activeUserId != null) {
      unawaited(refresh());
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 350), refresh),
      );
    }
  }

  Future<void> readComplete(String blogId) async {
    final auth = ref.read(authProvider);
    if (_activeUserId == null) {
      if (auth case Authenticated(:final userId)) {
        await _syncSignedIn(userId);
      }
    }
    if (_activeUserId == null) return;
    await recordLocalGain(BuddyCareSource.blogRead, sourceId: blogId);
    try {
      await ref.read(buddyApiProvider).readComplete(blogId);
    } finally {
      await refresh();
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await _loadPreferences();
    if (prefs == null) return;
    try {
      if (_activeUserId case final userId?) {
        final json = BuddyMe(
          care: state.care,
          species: state.species,
          name: state.name,
          today: state.today,
          equipped: state.equipped,
          balance: state.balance,
          chosen: state.chosen,
        ).toJson();
        await prefs.setString('$_signedInKeyPrefix$userId', jsonEncode(json));
      } else {
        await prefs.setString(_guestKey, jsonEncode(state.care.toJson()));
      }
    } catch (_) {
      // Buddy care stays usable when its optional local cache is unavailable.
    }
  }

  /// Changes the server equipped slot with an optimistic local look update.
  /// [assetKey] is supplied by the selecting UI so the new item can paint
  /// before the server returns its canonical item record.
  Future<void> equip(
    BuddyItemSlot slot,
    String? itemId, {
    String? assetKey,
  }) async {
    final userId = _activeUserId;
    if (userId == null || state.userId != userId) {
      throw StateError('A signed-in buddy is required to equip items.');
    }
    final previous = state.equipped[slot];
    final version = (_equipVersions[slot] ?? 0) + 1;
    _equipVersions[slot] = version;
    final optimistic = Map<BuddyItemSlot, BuddyEquipped>.of(state.equipped);
    if (itemId == null) {
      optimistic.remove(slot);
    } else {
      optimistic[slot] = BuddyEquipped(
        slot: slot,
        itemId: itemId,
        assetKey: assetKey ?? '',
      );
    }
    state = state.copyWith(equipped: Map.unmodifiable(optimistic));
    await _saveCurrentState();
    try {
      final me = await ref.read(buddyApiProvider).equip(slot, itemId);
      if (!ref.mounted ||
          _activeUserId != userId ||
          _equipVersions[slot] != version) {
        return;
      }
      _applyServerState(me, userId, serverSynced: true);
      await _saveCurrentState();
    } catch (_) {
      if (ref.mounted &&
          _activeUserId == userId &&
          _equipVersions[slot] == version) {
        final rollback = Map<BuddyItemSlot, BuddyEquipped>.of(state.equipped);
        if (previous == null) {
          rollback.remove(slot);
        } else {
          rollback[slot] = previous;
        }
        state = state.copyWith(equipped: Map.unmodifiable(rollback));
        await _saveCurrentState();
      }
      rethrow;
    }
  }

  Future<SharedPreferences?> _loadPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<MascotProfile> _profileFromPreferences(SharedPreferences prefs) async {
    final species =
        MascotSpecies.values
            .where((value) => value.name == prefs.getString(_guestSpeciesKey))
            .firstOrNull ??
        MascotSpecies.crocodile;
    final storedName = prefs.getString(_guestNameKey)?.trim();
    return MascotProfile(
      species: species,
      name: storedName?.isNotEmpty == true
          ? storedName!
          : MascotProfile.defaultName(species),
    );
  }

  List<BuddyTodayAction> _todayFromCare(BuddyCare care) => [
    for (final source in BuddyCareSource.values)
      BuddyTodayAction(
        key: source.key,
        done: (care.dailyCounts[source] ?? 0) > 0,
        count: care.dailyCounts[source] ?? 0,
        cap: source.dailyCap,
      ),
  ];
}

final buddyCareProvider = NotifierProvider<BuddyCareNotifier, BuddyCareState>(
  BuddyCareNotifier.new,
);

final buddyLookProvider = Provider<PublicBuddyLook>((ref) {
  final buddy = ref.watch(buddyCareProvider);
  return PublicBuddyLook(
    species: buddy.species,
    name: buddy.name,
    equipped: Map.unmodifiable({
      for (final entry in buddy.equipped.entries)
        if (entry.value.assetKey.isNotEmpty) entry.key: entry.value.assetKey,
    }),
  );
});
