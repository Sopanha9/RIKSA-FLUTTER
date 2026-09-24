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

  BuddyCareState copyWith({
    BuddyCare? care,
    MascotSpecies? species,
    String? name,
    List<BuddyTodayAction>? today,
    String? userId,
    bool clearUser = false,
  }) => BuddyCareState(
    care: care ?? this.care,
    species: species ?? this.species,
    name: name ?? this.name,
    today: today ?? this.today,
    userId: clearUser ? null : userId ?? this.userId,
  );

  factory BuddyCareState.fromMe(BuddyMe me, {String? userId}) => BuddyCareState(
    care: me.care,
    species: me.species,
    name: me.name,
    today: me.today,
    userId: userId,
  );
}

/// Restores a cached buddy immediately, then reconciles signed-in state with
/// the server. Guests keep lesson care on-device until they sign in.
class BuddyCareNotifier extends Notifier<BuddyCareState>
    with WidgetsBindingObserver {
  static const _guestKey = 'riksa_buddy_guest_care';
  static const _signedInKeyPrefix = 'riksa_buddy_care_user_';
  static const _speciesKey = 'riksa_mascot_species';
  static const _nameKey = 'riksa_mascot_name';

  String? _activeUserId;
  String? _syncingUserId;
  Future<void>? _syncOperation;

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
      if (profile == null ||
          (state.species == profile.species && state.name == profile.name)) {
        return;
      }
      state = state.copyWith(species: profile.species, name: profile.name);
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
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_signedInKeyPrefix$userId';
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      final cached = BuddyMe.fromJson(
        Map<String, dynamic>.from(jsonDecode(cachedJson) as Map),
      );
      _applyServerState(cached, userId);
    }

    try {
      final guestJson = prefs.getString(_guestKey);
      final BuddyMe remote;
      if (guestJson != null) {
        final guestCare = BuddyCare.fromJson(
          Map<String, dynamic>.from(jsonDecode(guestJson) as Map),
        );
        final profile = await _profileFromPreferences(prefs);
        remote = await ref
            .read(buddyApiProvider)
            .updateMe(
              species: profile.species,
              name: profile.name,
              guestEnergy: guestCare.energy,
              guestBond: guestCare.bond,
            );
        await prefs.remove(_guestKey);
      } else {
        remote = await ref.read(buddyApiProvider).getMe();
      }
      if (!ref.mounted || _syncingUserId != userId) return;
      _activeUserId = userId;
      await prefs.setString(cacheKey, jsonEncode(remote.toJson()));
      _applyServerState(remote, userId);
    } catch (_) {
      if (cachedJson == null && ref.mounted) {
        _activeUserId = userId;
        state = state.copyWith(userId: userId);
      }
    }
  }

  void _applyServerState(BuddyMe me, String userId) {
    _activeUserId = userId;
    state = BuddyCareState.fromMe(me, userId: userId);
    unawaited(
      ref.read(mascotProvider.notifier).acceptRemoteChoice(me.species, me.name),
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
      _applyServerState(me, userId);
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
    final prefs = await SharedPreferences.getInstance();
    if (_activeUserId case final userId?) {
      final json = BuddyMe(
        care: state.care,
        species: state.species,
        name: state.name,
        today: state.today,
      ).toJson();
      await prefs.setString('$_signedInKeyPrefix$userId', jsonEncode(json));
    } else {
      await prefs.setString(_guestKey, jsonEncode(state.care.toJson()));
    }
  }

  Future<MascotProfile> _profileFromPreferences(SharedPreferences prefs) async {
    final species =
        MascotSpecies.values
            .where((value) => value.name == prefs.getString(_speciesKey))
            .firstOrNull ??
        MascotSpecies.crocodile;
    final storedName = prefs.getString(_nameKey)?.trim();
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
