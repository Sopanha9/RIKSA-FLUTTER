import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/current_user_provider.dart';
import '../data/buddy_api.dart';
import '../domain/mascot.dart';

/// The learner's own buddy: which species, and what they called it.
@immutable
class MascotProfile {
  const MascotProfile({required this.species, required this.name});

  final MascotSpecies species;
  final String name;

  static const maxNameLength = 16;

  static String defaultName(MascotSpecies species) => switch (species) {
    MascotSpecies.crocodile => 'Croco',
    MascotSpecies.capybara => 'Capy',
  };
}

@immutable
class MascotState {
  const MascotState({required this.isReady, this.profile});

  const MascotState.loading() : isReady = false, profile = null;

  final bool isReady;

  /// Null until the learner has chosen a buddy.
  final MascotProfile? profile;
}

/// Restores and saves the chosen mascot on this device.
class MascotNotifier extends Notifier<MascotState> {
  static const String _guestSpeciesKey = 'riksa_mascot_species_guest';
  static const String _guestNameKey = 'riksa_mascot_name_guest';
  static const String _legacySpeciesKey = 'riksa_mascot_species';
  static const String _legacyNameKey = 'riksa_mascot_name';
  static const String _legacyCleanupKey = 'riksa_mascot_global_keys_cleared';
  static const String guestChoicePendingKey =
      'riksa_mascot_guest_choice_pending';
  bool _changedInSession = false;
  String? _userId;
  int _restoreVersion = 0;

  @override
  MascotState build() {
    final userId = watchCurrentUserId(ref);
    _userId = userId;
    _changedInSession = false;
    final version = ++_restoreVersion;
    unawaited(_restore(userId, version));
    return const MascotState.loading();
  }

  Future<void> _restore(String? userId, int version) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await _clearLegacyGlobalKeysOnce(preferences);
      final speciesName = preferences.getString(_speciesKeyFor(userId));
      final species = MascotSpecies.values
          .where((value) => value.name == speciesName)
          .firstOrNull;
      if (_changedInSession ||
          version != _restoreVersion ||
          _userId != userId ||
          !ref.mounted) {
        return;
      }
      state = MascotState(
        isReady: true,
        profile: species == null
            ? null
            : MascotProfile(
                species: species,
                name:
                    preferences.getString(_nameKeyFor(userId)) ??
                    MascotProfile.defaultName(species),
              ),
      );
    } catch (_) {
      if (version == _restoreVersion && _userId == userId && ref.mounted) {
        state = const MascotState(isReady: true);
      }
    }
  }

  /// Saves the choice. A blank name falls back to the species' default.
  Future<void> choose(MascotSpecies species, String name) async {
    _changedInSession = true;
    final userId = _userId;
    final trimmed = name.trim();
    final profile = MascotProfile(
      species: species,
      name: trimmed.isEmpty
          ? MascotProfile.defaultName(species)
          : trimmed.characters.take(MascotProfile.maxNameLength).toString(),
    );
    state = MascotState(isReady: true, profile: profile);
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_speciesKeyFor(userId), species.name),
      preferences.setString(_nameKeyFor(userId), profile.name),
      if (userId == null) preferences.setBool(guestChoicePendingKey, true),
    ]);
    if (userId != null) {
      try {
        final remote = await ref
            .read(buddyApiProvider)
            .updateMe(species: species, name: profile.name);
        if (ref.mounted && _userId == userId) {
          await acceptRemoteChoice(remote.species, remote.name, userId: userId);
          final preferences = await SharedPreferences.getInstance();
          await preferences.remove(guestChoicePendingKey);
        }
      } catch (_) {
        // Keep the choice locally available while offline. The next buddy
        // sync will reconcile it with the server profile.
      }
    }
  }

  /// Applies the server's canonical species and name without sending another
  /// write back to the same endpoint.
  Future<void> acceptRemoteChoice(
    MascotSpecies species,
    String name, {
    String? userId,
  }) async {
    final ownerId = userId ?? _userId;
    if (ownerId != _userId) return;
    _changedInSession = true;
    final profile = MascotProfile(
      species: species,
      name: name.trim().isEmpty
          ? MascotProfile.defaultName(species)
          : name.trim().characters.take(MascotProfile.maxNameLength).toString(),
    );
    state = MascotState(isReady: true, profile: profile);
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_speciesKeyFor(ownerId), profile.species.name),
      preferences.setString(_nameKeyFor(ownerId), profile.name),
    ]);
  }

  static String _speciesKeyFor(String? userId) =>
      userId == null || userId.isEmpty
      ? _guestSpeciesKey
      : 'riksa_mascot_species_$userId';

  static String _nameKeyFor(String? userId) => userId == null || userId.isEmpty
      ? _guestNameKey
      : 'riksa_mascot_name_$userId';

  static Future<void> _clearLegacyGlobalKeysOnce(
    SharedPreferences preferences,
  ) async {
    if (preferences.getBool(_legacyCleanupKey) == true) return;
    try {
      // The old keys held this device's choice. Signed-in accounts get their
      // buddy from the server, so the device choice becomes the guest's.
      final legacySpecies = preferences.getString(_legacySpeciesKey);
      if (legacySpecies != null &&
          preferences.getString(_guestSpeciesKey) == null) {
        await preferences.setString(_guestSpeciesKey, legacySpecies);
        final legacyName = preferences.getString(_legacyNameKey);
        if (legacyName != null) {
          await preferences.setString(_guestNameKey, legacyName);
        }
      }
      await preferences.remove(_legacySpeciesKey);
      await preferences.remove(_legacyNameKey);
      await preferences.setBool(_legacyCleanupKey, true);
    } catch (_) {
      // Stale global values are never read, even if cleanup must be retried.
    }
  }
}

final mascotProvider = NotifierProvider<MascotNotifier, MascotState>(
  MascotNotifier.new,
);
