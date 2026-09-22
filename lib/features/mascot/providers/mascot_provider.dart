import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }
}

final mascotProvider = NotifierProvider<MascotNotifier, MascotState>(
  MascotNotifier.new,
);
