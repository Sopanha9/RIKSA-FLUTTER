import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class LocaleState {
  const LocaleState({
    required this.locale,
    required this.isReady,
    required this.hasSelection,
  });

  const LocaleState.loading()
    : locale = const Locale('en'),
      isReady = false,
      hasSelection = false;

  final Locale locale;
  final bool isReady;
  final bool hasSelection;
}

/// Restores the selected locale and separately remembers whether onboarding
/// was completed. English is therefore not confused with an unset default.
class LocaleNotifier extends Notifier<LocaleState> {
  static const String _localeKey = 'riksa_locale';
  static const String _selectedKey = 'riksa_locale_selected';

  @override
  LocaleState build() {
    unawaited(_restore());
    return const LocaleState.loading();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_localeKey);
    final hasSelection = preferences.getBool(_selectedKey) ?? saved != null;
    state = LocaleState(
      locale: Locale(saved == 'km' ? 'km' : 'en'),
      isReady: true,
      hasSelection: hasSelection,
    );
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = Locale(locale.languageCode == 'km' ? 'km' : 'en');
    state = LocaleState(locale: normalized, isReady: true, hasSelection: true);
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_localeKey, normalized.languageCode),
      preferences.setBool(_selectedKey, true),
    ]);
  }

  Future<void> toggle() {
    return setLocale(
      state.locale.languageCode == 'en'
          ? const Locale('km')
          : const Locale('en'),
    );
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
