import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/mascot/domain/buddy_behavior.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';

void main() {
  group('BuddyBehavior', () {
    test('reserves a full-body reaction for lesson completion', () {
      final reaction = BuddyBehavior.resolve(BuddyEvent.lessonCompleted);

      expect(reaction.presentation, BuddyPresentation.earnedMoment);
      expect(reaction.mood, MascotMood.trophy);
      expect(reaction.speechPolicy, BuddySpeechPolicy.earned);
    });

    test('uses supportive faces without speech for common feedback', () {
      expect(
        BuddyBehavior.resolve(BuddyEvent.answerCorrect).face,
        MascotFace.proud,
      );
      final incorrect = BuddyBehavior.resolve(BuddyEvent.answerIncorrect);
      expect(incorrect.face, MascotFace.thinking);
      expect(incorrect.speechAllowed, isFalse);
    });

    test('turns disabled reactions into a neutral static identity', () {
      final reaction = BuddyBehavior.resolve(
        BuddyEvent.rankImproved,
        reactionsEnabled: false,
      );

      expect(reaction.presentation, BuddyPresentation.inline);
      expect(reaction.face, MascotFace.neutral);
      expect(reaction.speechAllowed, isFalse);
      expect(reaction.mood, isNull);
    });

    test('never assigns punitive expressions to study events', () {
      for (final event in BuddyEvent.values) {
        final face = BuddyBehavior.resolve(event).face;
        expect(face, isNot(anyOf(MascotFace.sad, MascotFace.crying, MascotFace.annoyed)));
      }
    });
  });
}
