import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';

void main() {
  test('gamification profile keeps spendable XP separate from total XP', () {
    final profile = GamificationProfile.fromJson({
      'totalXp': 1520,
      'xpBalance': 1240,
      'currentStreak': 3,
      'highestStreak': 4,
      'xpToNext': 480,
    });

    expect(profile.totalXp, 1520);
    expect(profile.xpBalance, 1240);
  });

  test('older profile payloads default spendable XP to zero', () {
    final profile = GamificationProfile.fromJson({
      'totalXp': 1520,
      'currentStreak': 3,
      'highestStreak': 4,
      'xpToNext': 480,
    });

    expect(profile.xpBalance, 0);
  });
}
