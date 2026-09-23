import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuddyPreferencesNotifier extends Notifier<bool> {
  static const storageKey = 'riksa_buddy_reactions_enabled';

  @override
  bool build() {
    unawaited(_restore());
    return true;
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(storageKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(storageKey, enabled);
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
