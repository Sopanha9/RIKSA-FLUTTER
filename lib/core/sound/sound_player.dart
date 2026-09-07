import 'package:audioplayers/audioplayers.dart';

/// The slice of audio playback this app needs.
///
/// Keeping the seam this narrow means the feedback rules — mute, haptics,
/// restart-don't-overlap — are testable without a platform channel, and that
/// swapping the audio package touches exactly one class.
abstract class SoundPlayer {
  /// Plays a file from `assets/audio/`, restarting if already sounding.
  Future<void> play(String asset);

  Future<void> stop();

  Future<void> dispose();
}

/// [SoundPlayer] backed by the `audioplayers` package.
class AudioPlayersSoundPlayer implements SoundPlayer {
  AudioPlayersSoundPlayer() : _player = AudioPlayer() {
    _player
      ..setReleaseMode(ReleaseMode.stop)
      // Ambient obeys the iOS silent switch and mixes with, rather than stops,
      // whatever the learner is already listening to.
      ..setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
  }

  final AudioPlayer _player;

  @override
  Future<void> play(String asset) async {
    await _player.stop();
    await _player.play(AssetSource('audio/$asset'));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
