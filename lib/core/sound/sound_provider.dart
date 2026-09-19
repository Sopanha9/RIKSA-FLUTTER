import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_sound.dart';
import 'sound_service.dart';

/// Whether learning sounds play. Persisted per device, not per account: it
/// describes where the phone is (a classroom, a bus), not who is holding it.
class SoundEnabledNotifier extends Notifier<bool> {
  static const _key = 'riksa_learning_sound_enabled';

  @override
  bool build() {
    _restore().ignore();
    return true;
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getBool(_key);
    if (saved != null && saved != state) {
      state = saved;
      ref.read(soundServiceProvider).muted = !saved;
    }
  }

  Future<void> set({required bool enabled}) async {
    state = enabled;
    ref.read(soundServiceProvider).muted = !enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, enabled);
  }

  Future<void> toggle() => set(enabled: !state);
}

final soundEnabledProvider = NotifierProvider<SoundEnabledNotifier, bool>(
  SoundEnabledNotifier.new,
);

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => service.dispose().ignore());
  return service;
});

/// Plays a cue for a feedback moment.
///
/// Screens call this rather than touching [SoundService] directly. Note it does
/// not check the preference itself: muting silences the audio but keeps the
/// haptic, which is the whole point of having one. [SoundService.play] owns
/// that distinction.
extension PlayLearningSound on WidgetRef {
  void playSound(LearningSound sound) {
    // Reading the preference keeps the service's muted flag in sync on the
    // first play after a restore, before any toggle has happened.
    final enabled = read(soundEnabledProvider);
    final service = read(soundServiceProvider);
    if (service.muted == enabled) service.muted = !enabled;
    service.play(sound);
  }
}
