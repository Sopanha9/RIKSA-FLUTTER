import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';

void main() {
  test('measures progress through the current tier, not from zero XP', () {
    // Diamond starts at 2,500 and Legend at 5,000, so 4,050 XP is 1,550 into
    // a 2,500 band: 62%. Measuring from zero would claim 81%.
    final profile = GamificationProfile.fromJson({
      'totalXp': 4050,
      'currentStreak': 20,
      'highestStreak': 20,
      'currentTier': 'DIAMOND',
      'currentTierMinXp': 2500,
      'nextTier': 'LEGEND',
      'nextTierMinXp': 5000,
      'xpToNext': 950,
    });

    expect(profile.xpIntoTier, 1550);
    expect(profile.tierBandXp, 2500);
    expect(profile.nextTierProgress, closeTo(.62, .001));
    expect(profile.isTopTier, isFalse);
  });

  test('a learner who just entered a tier has not climbed any of it', () {
    final profile = GamificationProfile.fromJson({
      'totalXp': 2500,
      'currentTier': 'DIAMOND',
      'currentTierMinXp': 2500,
      'nextTier': 'LEGEND',
      'nextTierMinXp': 5000,
      'xpToNext': 2500,
    });

    expect(profile.xpIntoTier, 0);
    expect(profile.nextTierProgress, 0);
  });

  test('the top of the ladder reports no band and no next tier', () {
    final profile = GamificationProfile.fromJson({
      'totalXp': 6200,
      'currentTier': 'LEGEND',
      'currentTierMinXp': 5000,
      'nextTierMinXp': 0,
      'xpToNext': 0,
    });

    expect(profile.isTopTier, isTrue);
    expect(profile.tierBandXp, 0);
    expect(profile.nextTierProgress, 1);
  });

  test('falls back to the old measure when the server omits tier floors', () {
    final profile = GamificationProfile.fromJson({
      'totalXp': 1520,
      'currentStreak': 14,
      'highestStreak': 14,
      'currentTier': 'GOLD',
      'currentTierIcon': '/icons/gold.png',
      'nextTier': 'PLATINUM',
      'xpToNext': 480,
    });

    expect(profile.totalXp, 1520);
    expect(profile.currentTier, 'GOLD');
    expect(profile.nextTier, 'PLATINUM');
    expect(profile.nextTierProgress, closeTo(.76, .001));
  });

  test('parses achievement progress and XP cursor activity', () {
    final achievement = ProfileAchievement.fromJson({
      'id': 'ach-1',
      'name': 'Week Warrior',
      'description': 'Maintain a seven-day streak',
      'earned': true,
      'progress': 7,
      'progressMax': 7,
      'progressPercent': 1,
      'rarity': 'RARE',
      'xpReward': 50,
      'unlockedAt': '2026-08-20T10:00:00Z',
    });
    final page = XpActivityPage.fromJson({
      'edges': [
        {
          'id': 'tx-1',
          'amount': 30,
          'sourceType': 'LESSON_COMPLETION',
          'runningBalance': 1520,
          'createdAt': '2026-08-22T10:00:00Z',
        },
      ],
      'hasNextPage': true,
      'endCursor': 'cursor-1',
    });

    expect(achievement.earned, isTrue);
    expect(achievement.progressPercent, 1);
    expect(page.activities.single.sourceType, 'LESSON_COMPLETION');
    expect(page.hasNextPage, isTrue);
    expect(page.endCursor, 'cursor-1');
  });

  test('parses country and province leaderboard positions', () {
    final rank = LeaderboardRank.fromJson({
      'countryRank': 12,
      'countryScore': 1520,
      'countryTier': 'GOLD',
      'provinceRank': 3,
      'provinceScore': 1520,
      'provinceTier': 'GOLD',
    });

    expect(rank.countryRank, 12);
    expect(rank.provinceRank, 3);
    expect(rank.countryTier, 'GOLD');
  });

  test(
    'leaderboard rows tolerate old payloads and parse public buddy looks',
    () {
      final oldRow = LeaderboardRow.fromJson({
        'rank': 5,
        'userId': 'old-user',
        'score': 120,
      });
      final row = LeaderboardRow.fromJson({
        'rank': 1,
        'userId': 'new-user',
        'score': 1500,
        'buddy': {
          'species': 'crocodile',
          'name': 'Rex',
          'equipped': {'EYEWEAR': 'glasses_round'},
        },
      });

      expect(oldRow.buddy, isNull);
      expect(row.buddy?.species.name, 'crocodile');
      expect(row.buddy?.equipped.values, contains('glasses_round'));
    },
  );
}
