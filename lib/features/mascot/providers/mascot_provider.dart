import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';
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
  static const String _speciesKey = 'riksa_mascot_species';
  static const String _nameKey = 'riksa_mascot_name';
  bool _changedInSession = false;

  @override
  MascotState build() {
    unawaited(_restore());
    return const MascotState.loading();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final speciesName = preferences.getString(_speciesKey);
    final species = MascotSpecies.values
        .where((value) => value.name == speciesName)
        .firstOrNull;
    if (_changedInSession) return;
    state = MascotState(
      isReady: true,
      profile: species == null
          ? null
          : MascotProfile(
              species: species,
              name:
                  preferences.getString(_nameKey) ??
                  MascotProfile.defaultName(species),
            ),
    );
  }

  /// Saves the choice. A blank name falls back to the species' default.
  Future<void> choose(MascotSpecies species, String name) async {
    _changedInSession = true;
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
      preferences.setString(_speciesKey, species.name),
      preferences.setString(_nameKey, profile.name),
    ]);
    if (ref.read(authProvider) is Authenticated) {
      try {
        final remote = await ref
            .read(buddyApiProvider)
            .updateMe(species: species, name: profile.name);
        await acceptRemoteChoice(remote.species, remote.name);
      } catch (_) {
        // Keep the choice locally available while offline. The next buddy
        // sync will reconcile it with the server profile.
      }
    }
  }

  /// Applies the server's canonical species and name without sending another
  /// write back to the same endpoint.
  Future<void> acceptRemoteChoice(MascotSpecies species, String name) async {
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
      preferences.setString(_speciesKey, profile.species.name),
      preferences.setString(_nameKey, profile.name),
    ]);
  }
}

final mascotProvider = NotifierProvider<MascotNotifier, MascotState>(
  MascotNotifier.new,
);
