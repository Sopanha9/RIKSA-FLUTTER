import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';

void main() {
  test('parses the public profile contract without private account fields', () {
    final profile = PublicProfile.fromJson({
      'user': {
        'id': 'user-2',
        'username': 'dara',
        'displayName': 'Dara',
        'avatarUrl': 'https://example.test/dara.png',
        'bio': 'Learning in public.',
        'isVerified': true,
        'email': 'must-not-be-modeled@example.test',
        'phoneNumber': '+85500000000',
      },
      'gamification': {
        'totalXp': 2400,
        'currentTier': 'SCHOLAR',
        'currentTierIcon': 'https://example.test/scholar.png',
      },
      'achievements': [
        {
          'id': 'achievement-1',
          'name': 'Study Starter',
          'description': 'Completed a first lesson.',
          'iconUrl': 'https://example.test/achievement.png',
          'rarity': 'RARE',
          'unlockedAt': '2026-08-01T12:00:00Z',
          'progress': 99,
        },
      ],
      'rank': {'countryRank': 42, 'provinceRank': 5},
      'coverUrl': null,
    });

    expect(profile.id, 'user-2');
    expect(profile.username, 'dara');
    expect(profile.displayName, 'Dara');
    expect(profile.isVerified, isTrue);
    expect(profile.totalXp, 2400);
    expect(profile.currentTier, 'SCHOLAR');
    expect(profile.achievements.single.name, 'Study Starter');
    expect(
      profile.achievements.single.unlockedAt,
      DateTime.utc(2026, 8, 1, 12),
    );
    expect(profile.rank?.countryRank, 42);
    expect(profile.rank?.provinceRank, 5);
    expect(profile.coverUrl, isNull);
    final serialized = profile.toJson();
    expect(serialized.toString(), isNot(contains('must-not-be-modeled')));
    expect(serialized.toString(), isNot(contains('phoneNumber')));
    expect(serialized.toString(), isNot(contains('emailVerified')));
  });

  test('uses defensive public-safe defaults for malformed optional data', () {
    final profile = PublicProfile.fromJson({
      'user': {'id': 7},
      'gamification': {'totalXp': 'not-a-number'},
      'achievements': [null, 'invalid', <String, Object?>{}],
      'rank': 'invalid',
      'coverUrl': '   ',
    });

    expect(profile.id, '7');
    expect(profile.username, '');
    expect(profile.displayName, '');
    expect(profile.isVerified, isFalse);
    expect(profile.totalXp, 0);
    expect(profile.currentTier, 'STARTER');
    expect(profile.achievements, isEmpty);
    expect(profile.rank, isNull);
    expect(profile.coverUrl, isNull);
  });
}
