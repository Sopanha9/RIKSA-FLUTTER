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
    this.hasViewedOnboarding = false,
    this.hasCompletedOnboarding = false,
    this.pendingProvinceId,
  });

  const LocaleState.loading()
    : locale = const Locale('en'),
      isReady = false,
      hasSelection = false,
      hasViewedOnboarding = false,
      hasCompletedOnboarding = false,
      pendingProvinceId = null;

  final Locale locale;
  final bool isReady;
  final bool hasSelection;
  final bool hasViewedOnboarding;
  final bool hasCompletedOnboarding;
  final String? pendingProvinceId;
}

/// Restores the selected locale and separately remembers whether onboarding
/// was completed. English is therefore not confused with an unset default.
class LocaleNotifier extends Notifier<LocaleState> {
  static const String _localeKey = 'riksa_locale';
  static const String _selectedKey = 'riksa_locale_selected';
  static const String _viewedOnboardingKey = 'riksa_onboarding_viewed';
  static const String _onboardingKey = 'riksa_onboarding_completed';
  static const String _pendingProvinceKey = 'riksa_pending_province_id';

  @override
  LocaleState build() {
    unawaited(_restore());
    return const LocaleState.loading();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_localeKey);
    final hasSelection = preferences.getBool(_selectedKey) ?? saved != null;
    final hasViewedOnboarding =
        preferences.getBool(_viewedOnboardingKey) ?? false;
    final hasCompletedOnboarding = preferences.getBool(_onboardingKey) ?? false;
    state = LocaleState(
      locale: Locale(saved == 'km' ? 'km' : 'en'),
      isReady: true,
      hasSelection: hasSelection,
      hasViewedOnboarding: hasViewedOnboarding,
      hasCompletedOnboarding: hasCompletedOnboarding,
      pendingProvinceId: preferences.getString(_pendingProvinceKey),
    );
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = Locale(locale.languageCode == 'km' ? 'km' : 'en');
    state = LocaleState(
      locale: normalized,
      isReady: true,
      hasSelection: true,
      hasViewedOnboarding: state.hasViewedOnboarding,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
      pendingProvinceId: state.pendingProvinceId,
    );
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

  Future<void> completeIntro() async {
    state = LocaleState(
      locale: state.locale,
      isReady: true,
      hasSelection: state.hasSelection,
      hasViewedOnboarding: true,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
      pendingProvinceId: state.pendingProvinceId,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_viewedOnboardingKey, true);
  }

  Future<void> savePendingProvince(String provinceId) async {
    state = LocaleState(
      locale: state.locale,
      isReady: true,
      hasSelection: state.hasSelection,
      hasViewedOnboarding: true,
      hasCompletedOnboarding: false,
      pendingProvinceId: provinceId,
    );
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_viewedOnboardingKey, true),
      preferences.setString(_pendingProvinceKey, provinceId),
    ]);
  }

  Future<void> completeOnboarding() async {
    state = LocaleState(
      locale: state.locale,
      isReady: true,
      hasSelection: state.hasSelection,
      hasViewedOnboarding: true,
      hasCompletedOnboarding: true,
      pendingProvinceId: null,
    );
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_viewedOnboardingKey, true),
      preferences.setBool(_onboardingKey, true),
      preferences.remove(_pendingProvinceKey),
    ]);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
