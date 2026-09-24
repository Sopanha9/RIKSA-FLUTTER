import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/mascot/domain/buddy_care.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';

void main() {
  group('BuddyCare decay', () {
    final now = DateTime.utc(2026, 9, 24, 12);

    BuddyCare careAt(int energy) => BuddyCare(
      energy: energy,
      bond: 0,
      updatedAt: now,
      careDay: phnomPenhCareDay(now),
    );

    test('decays once per complete 72 minutes', () {
      expect(careAt(100).settle(now).energy, 100);
      expect(
        careAt(100).settle(now.add(const Duration(minutes: 71))).energy,
        100,
      );
      expect(
        careAt(100).settle(now.add(const Duration(minutes: 72))).energy,
        99,
      );
    });

    test('clamps at zero after prolonged absence', () {
      expect(
        careAt(100).settle(now.add(const Duration(minutes: 7200))).energy,
        0,
      );
      expect(
        careAt(1).settle(now.add(const Duration(minutes: 7200))).energy,
        0,
      );
    });
  });

  test(
    'lesson energy is uncapped while bond is capped at five lessons/day',
    () {
      final now = DateTime.utc(2026, 9, 24, 12);
      var care = BuddyCare.initial(now).copyWith(energy: 0);
      for (var lesson = 0; lesson < 6; lesson++) {
        care = care.gain(
          BuddyCareSource.lesson,
          now.add(Duration(seconds: lesson)),
          sourceId: 'lesson-$lesson',
        );
      }

      expect(care.energy, 100);
      expect(care.bond, 50);
      expect(care.countFor(BuddyCareSource.lesson, now), 6);
    },
  );

  test(
    'blog reads and posts respect their daily caps and source idempotency',
    () {
      final now = DateTime.utc(2026, 9, 24, 12);
      var care = BuddyCare.initial(now).copyWith(energy: 0);
      care = care.gain(BuddyCareSource.blogRead, now, sourceId: 'blog-a');
      final duplicate = care.gain(
        BuddyCareSource.blogRead,
        now,
        sourceId: 'blog-a',
      );
      expect(duplicate.energy, 10);
      care = care.gain(BuddyCareSource.blogRead, now, sourceId: 'blog-b');
      care = care.gain(BuddyCareSource.blogRead, now, sourceId: 'blog-c');
      expect(care.energy, 20);
      expect(care.bond, 6);
      expect(care.countFor(BuddyCareSource.blogRead, now), 2);

      care = care.gain(BuddyCareSource.post, now, sourceId: 'post-a');
      care = care.gain(BuddyCareSource.post, now, sourceId: 'post-b');
      expect(care.energy, 30);
      expect(care.bond, 9);
      expect(care.countFor(BuddyCareSource.post, now), 1);
    },
  );

  test('care counts reset at the Phnom Penh midnight boundary', () {
    final beforeMidnight = DateTime.utc(2026, 9, 24, 16, 59);
    final afterMidnight = DateTime.utc(2026, 9, 24, 17, 1);
    expect(phnomPenhCareDay(beforeMidnight), '2026-09-24');
    expect(phnomPenhCareDay(afterMidnight), '2026-09-25');

    final care = BuddyCare.initial(
      beforeMidnight,
    ).gain(BuddyCareSource.post, beforeMidnight, sourceId: 'post-a');
    final nextDay = care.gain(
      BuddyCareSource.post,
      afterMidnight,
      sourceId: 'post-b',
    );
    expect(nextDay.countFor(BuddyCareSource.post, afterMidnight), 1);
    expect(nextDay.bond, 6);
  });

  test('bond levels follow the square root thresholds', () {
    expect(_careWithBond(0).bondLevel, 1);
    expect(_careWithBond(14).bondLevel, 1);
    expect(_careWithBond(15).bondLevel, 2);
    expect(_careWithBond(60).bondLevel, 3);
    expect(_careWithBond(135).bondLevel, 4);
    expect(_careWithBond(240).bondLevel, 5);
  });

  test('vitality never turns absence into a sad or crying face', () {
    expect(_careWithEnergy(90).vitality, BuddyVitality.lively);
    expect(_careWithEnergy(50).vitality, BuddyVitality.steady);
    expect(_careWithEnergy(20).vitality, BuddyVitality.sleepy);
    expect(_careWithEnergy(0).vitality, BuddyVitality.napping);
    expect(moodFor(BuddyVitality.napping), MascotMood.sleep);
    expect(faceFor(BuddyVitality.napping), MascotFace.sleepy);
    for (final vitality in BuddyVitality.values) {
      expect(faceFor(vitality), isNot(MascotFace.sad));
      expect(faceFor(vitality), isNot(MascotFace.crying));
      expect(moodFor(vitality), isNot(MascotMood.sad));
    }
  });
}

BuddyCare _careWithBond(int bond) =>
    BuddyCare(energy: 60, bond: bond, updatedAt: DateTime.utc(2026, 9, 24));

BuddyCare _careWithEnergy(int energy) =>
    BuddyCare(energy: energy, bond: 0, updatedAt: DateTime.utc(2026, 9, 24));
