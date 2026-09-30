import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'learning_sound.dart';
import 'sound_player.dart';

/// Plays the short feedback cues that punctuate a lesson.
///
/// Three rules shape this class:
///
/// * **Never block the caller.** Answering a question must not wait on audio,
///   so [play] returns immediately and failures are swallowed — a missing
///   codec should never break a lesson.
/// * **Never override the ringer switch.** [AudioPlayersSoundPlayer] uses the
///   ambient audio category, so a silenced phone stays silent. A learning app
///   that blares in a classroom gets deleted.
/// * **Always offer haptics.** They carry the feedback when sound is off,
///   which on a school device is most of the time — so muting silences the
///   audio and keeps the buzz.
class SoundService {
  SoundService({
    SoundPlayer Function()? createPlayer,
    this.enableHaptics = true,
  }) : _createPlayer = createPlayer ?? AudioPlayersSoundPlayer.new;

  final SoundPlayer Function() _createPlayer;
  final bool enableHaptics;

  /// One player per cue, so each keeps its own decoded asset.
  final Map<LearningSound, SoundPlayer> _players = {};
  bool _muted = false;
  bool _disposed = false;

  bool get muted => _muted;

  set muted(bool value) {
    _muted = value;
    if (value) {
      for (final player in _players.values) {
        _swallow(player.stop());
      }
    }
  }

  /// Plays [sound] and fires its haptic.
  ///
  /// Safe to call straight from a widget callback: it never throws and never
  /// awaits the audio finishing.
  void play(LearningSound sound) {
    _haptic(sound.haptic);
    if (_muted || _disposed) return;
    _swallow(_playAsset(sound));
  }

  Future<void> _playAsset(LearningSound sound) async {
    final player = _players.putIfAbsent(sound, _createPlayer);
    await player.play(sound.asset);
  }

  void _haptic(LearningHaptic haptic) {
    if (!enableHaptics) return;
    _swallow(switch (haptic) {
      LearningHaptic.light => HapticFeedback.lightImpact(),
      LearningHaptic.medium => HapticFeedback.mediumImpact(),
      LearningHaptic.heavy => HapticFeedback.heavyImpact(),
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final player in _players.values) {
      await _swallowed(player.dispose());
    }
    _players.clear();
  }

  /// Audio is decoration; a failure must never reach the learner.
  void _swallow(Future<void> future) => _swallowed(future);

  Future<void> _swallowed(Future<void> future) =>
      future.catchError((Object error, StackTrace stack) {
        if (kDebugMode) debugPrint('Sound failed: $error');
      });
}
