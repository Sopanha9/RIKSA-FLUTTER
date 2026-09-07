import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/sound/learning_sound.dart';
import 'package:riksa_app/core/sound/sound_player.dart';
import 'package:riksa_app/core/sound/sound_service.dart';

/// Sound is decoration: it must never block a learner, never throw, and never
/// override the ringer switch. Haptics are the part that survives muting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('every cue maps to a file that ships with the app', () {
    for (final sound in LearningSound.values) {
      expect(sound.asset, endsWith('.wav'), reason: sound.name);
      expect(sound.asset, isNot(contains('/')), reason: sound.name);
    }
    // Distinct files, or two moments would be indistinguishable.
    expect(
      LearningSound.values.map((s) => s.asset).toSet(),
      hasLength(LearningSound.values.length),
    );
  });

  test('a wrong answer buzzes harder than a correct one', () {
    expect(LearningSound.correct.haptic, LearningHaptic.light);
    expect(LearningSound.wrong.haptic, LearningHaptic.heavy);
  });

  test('a failing player never surfaces to the learner', () async {
    final service = SoundService(createPlayer: _BrokenPlayer.new);
    addTearDown(service.dispose);

    for (final sound in LearningSound.values) {
      expect(() => service.play(sound), returnsNormally);
    }
    await Future<void>.delayed(Duration.zero);
    // Haptics still fired, so the moment is not silent to the hand.
    expect(haptics, hasLength(LearningSound.values.length));
  });

  test('each cue plays its own asset', () async {
    final players = <_FakePlayer>[];
    final service = SoundService(
      createPlayer: () {
        final player = _FakePlayer();
        players.add(player);
        return player;
      },
    );
    addTearDown(service.dispose);

    service..play(LearningSound.correct)..play(LearningSound.wrong);
    await Future<void>.delayed(Duration.zero);

    expect(players.map((p) => p.played).toList(), [
      ['correct.wav'],
      ['wrong.wav'],
    ]);
  });

  test('repeating a cue reuses its player and restarts it', () async {
    final players = <_FakePlayer>[];
    final service = SoundService(
      createPlayer: () {
        final player = _FakePlayer();
        players.add(player);
        return player;
      },
    );
    addTearDown(service.dispose);

    service..play(LearningSound.correct)..play(LearningSound.correct);
    await Future<void>.delayed(Duration.zero);

    // Rapid answering must not stack a chorus of overlapping chimes.
    expect(players, hasLength(1));
    expect(players.single.played, ['correct.wav', 'correct.wav']);
  });

  test('muting silences audio but keeps the haptic', () async {
    final players = <_FakePlayer>[];
    final service = SoundService(
      createPlayer: () {
        final player = _FakePlayer();
        players.add(player);
        return player;
      },
    )..muted = true;
    addTearDown(service.dispose);

    service.play(LearningSound.correct);
    await Future<void>.delayed(Duration.zero);

    expect(players, isEmpty, reason: 'muted must not touch the audio layer');
    // The point of the haptic is that it still lands on a silenced phone.
    expect(haptics, hasLength(1));
  });

  test('haptics can be switched off independently', () async {
    final service = SoundService(
      createPlayer: _FakePlayer.new,
      enableHaptics: false,
    )..muted = true;
    addTearDown(service.dispose);

    service.play(LearningSound.wrong);
    await Future<void>.delayed(Duration.zero);

    expect(haptics, isEmpty);
  });

  test('play returns before any audio work happens', () {
    final service = SoundService(createPlayer: _SlowPlayer.new);
    addTearDown(service.dispose);

    final watch = Stopwatch()..start();
    service.play(LearningSound.lessonComplete);
    watch.stop();

    // Answering a question must not wait on a decoder.
    expect(watch.elapsedMilliseconds, lessThan(50));
  });
}

class _FakePlayer implements SoundPlayer {
  final played = <String>[];

  @override
  Future<void> play(String asset) async => played.add(asset);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _BrokenPlayer implements SoundPlayer {
  @override
  Future<void> play(String asset) async => throw StateError('no codec');

  @override
  Future<void> stop() async => throw StateError('no codec');

  @override
  Future<void> dispose() async {}
}

class _SlowPlayer implements SoundPlayer {
  @override
  Future<void> play(String asset) =>
      Future<void>.delayed(const Duration(seconds: 2));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
