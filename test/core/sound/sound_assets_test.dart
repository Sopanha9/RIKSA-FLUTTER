import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/sound/learning_sound.dart';

/// A cue that names a file the bundle does not carry fails silently at runtime,
/// which is exactly the kind of breakage nobody notices until a learner
/// mentions the app went quiet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sound in LearningSound.values) {
    test('${sound.name} ships real audio in the bundle', () async {
      final data = await rootBundle.load('assets/audio/${sound.asset}');

      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: 'suspiciously tiny',
      );

      // RIFF....WAVE — a real wave header, not a renamed placeholder.
      final bytes = data.buffer.asUint8List();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    });
  }

  test('cues stay short enough to feel instant', () async {
    for (final sound in LearningSound.values) {
      final data = await rootBundle.load('assets/audio/${sound.asset}');
      // 44.1kHz, 16-bit mono, plus a 44-byte header.
      final seconds = (data.lengthInBytes - 44) / (44100 * 2);
      expect(
        seconds,
        lessThan(2.0),
        reason: '${sound.asset} runs ${seconds.toStringAsFixed(2)}s',
      );
    }
  });
}
