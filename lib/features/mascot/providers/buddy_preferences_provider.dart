import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuddyPreferencesNotifier extends Notifier<bool> {
  static const storageKey = 'riksa_buddy_reactions_enabled';
  bool _changedInSession = false;

  @override
  bool build() {
    unawaited(_restore());
    // Stay quiet until persistence resolves so a stored opt-out can never
    // flash an autonomous reaction during startup.
    return false;
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!_changedInSession) {
        state = preferences.getBool(storageKey) ?? true;
      }
    } on MissingPluginException {
      // Keep reactions disabled when local preferences cannot be read.
    } on PlatformException {
      // A failed read must not interrupt screens that show the buddy.
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setBool(storageKey, enabled)) return false;
      _changedInSession = true;
      state = enabled;
      return true;
    } on Object {
      return false;
    }
  }
}

final buddyReactionsEnabledProvider =
    NotifierProvider<BuddyPreferencesNotifier, bool>(
      BuddyPreferencesNotifier.new,
    );

class BuddyHomeSpeechNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void consume() => state = false;
}

/// Session-only proactive speech budget. It intentionally is not persisted.
final buddyHomeSpeechAvailableProvider =
    NotifierProvider<BuddyHomeSpeechNotifier, bool>(
      BuddyHomeSpeechNotifier.new,
    );
