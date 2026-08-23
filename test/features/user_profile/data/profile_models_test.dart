import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';

void main() {
  test('parses the gamification profile and next-tier progress', () {
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
}
