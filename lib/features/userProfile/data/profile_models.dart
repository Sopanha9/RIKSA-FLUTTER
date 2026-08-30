library;

class GamificationProfile {
  const GamificationProfile({
    required this.totalXp,
    required this.currentStreak,
    required this.highestStreak,
    required this.xpToNext,
    this.currentTier,
    this.currentTierIcon,
    this.nextTier,
  });

  final int totalXp;
  final int currentStreak;
  final int highestStreak;
  final String? currentTier;
  final String? currentTierIcon;
  final String? nextTier;
  final int xpToNext;

  double get nextTierProgress {
    if (nextTier == null || xpToNext <= 0) return 1;
    final threshold = totalXp + xpToNext;
    if (threshold <= 0) return 0;
    return (totalXp / threshold).clamp(0, 1);
  }

  factory GamificationProfile.fromJson(Map<String, dynamic> json) =>
      GamificationProfile(
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        highestStreak: (json['highestStreak'] as num?)?.toInt() ?? 0,
        currentTier: json['currentTier'] as String?,
        currentTierIcon: json['currentTierIcon'] as String?,
        nextTier: json['nextTier'] as String?,
        xpToNext: (json['xpToNext'] as num?)?.toInt() ?? 0,
      );
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.earned,
    required this.progress,
    required this.progressMax,
    required this.progressPercent,
    required this.rarity,
    required this.xpReward,
    this.iconUrl,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final bool earned;
  final DateTime? unlockedAt;
  final int progress;
  final int progressMax;
  final double progressPercent;
  final String rarity;
  final int xpReward;

  factory ProfileAchievement.fromJson(Map<String, dynamic> json) =>
      ProfileAchievement(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        iconUrl: json['iconUrl'] as String?,
        earned: json['earned'] as bool? ?? false,
        unlockedAt: DateTime.tryParse(json['unlockedAt']?.toString() ?? ''),
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        progressMax: (json['progressMax'] as num?)?.toInt() ?? 0,
        progressPercent: ((json['progressPercent'] as num?)?.toDouble() ?? 0)
            .clamp(0, 1),
        rarity: json['rarity'] as String? ?? 'COMMON',
        xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      );
}

class XpActivity {
  const XpActivity({
    required this.id,
    required this.amount,
    required this.sourceType,
    required this.runningBalance,
    required this.createdAt,
    this.sourceId,
  });

  final String id;
  final int amount;
  final String sourceType;
  final String? sourceId;
  final int runningBalance;
  final DateTime? createdAt;

  factory XpActivity.fromJson(Map<String, dynamic> json) => XpActivity(
    id: json['id']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    sourceType: json['sourceType'] as String? ?? 'XP_REWARD',
    sourceId: json['sourceId']?.toString(),
    runningBalance: (json['runningBalance'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class XpActivityPage {
  const XpActivityPage({
    required this.activities,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<XpActivity> activities;
  final bool hasNextPage;
  final String? endCursor;

  factory XpActivityPage.fromJson(Map<String, dynamic> json) => XpActivityPage(
    activities: ((json['edges'] as List?) ?? const [])
        .map(
          (item) => XpActivity.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    hasNextPage: json['hasNextPage'] as bool? ?? false,
    endCursor: json['endCursor'] as String?,
  );
}

class RankHistoryEntry {
  const RankHistoryEntry({
    required this.id,
    required this.scope,
    required this.oldRank,
    required this.newRank,
    this.changedAt,
  });
  final String id;
  final String scope;
  final int oldRank;
  final int newRank;
  final DateTime? changedAt;
  factory RankHistoryEntry.fromJson(Map<String, dynamic> json) =>
      RankHistoryEntry(
        id: json['id']?.toString() ?? '',
        scope: json['scope'] as String? ?? 'GLOBAL',
        oldRank: (json['oldRank'] as num?)?.toInt() ?? 0,
        newRank: (json['newRank'] as num?)?.toInt() ?? 0,
        changedAt: DateTime.tryParse(json['changedAt']?.toString() ?? ''),
      );
}

class ProfileDashboardData {
  const ProfileDashboardData({
    required this.gamification,
    required this.achievements,
    required this.activities,
  });

  final GamificationProfile gamification;
  final List<ProfileAchievement> achievements;
  final List<XpActivity> activities;

  int get earnedAchievementCount =>
      achievements.where((achievement) => achievement.earned).length;
}

class LeaderboardRank {
  const LeaderboardRank({
    required this.countryRank,
    required this.countryScore,
    this.countryTier,
    this.provinceRank,
    this.provinceScore,
    this.provinceTier,
  });

  final int countryRank;
  final int countryScore;
  final String? countryTier;
  final int? provinceRank;
  final int? provinceScore;
  final String? provinceTier;

  factory LeaderboardRank.fromJson(Map<String, dynamic> json) =>
      LeaderboardRank(
        countryRank: (json['countryRank'] as num?)?.toInt() ?? 0,
        countryScore: (json['countryScore'] as num?)?.toInt() ?? 0,
        countryTier: json['countryTier'] as String?,
        provinceRank: (json['provinceRank'] as num?)?.toInt(),
        provinceScore: (json['provinceScore'] as num?)?.toInt(),
        provinceTier: json['provinceTier'] as String?,
      );
}

/// Board scope, mirroring the backend `ScopeType` enum (`COUNTRY`, `PROVINCE`).
enum LeaderboardScope { country, province }

extension LeaderboardScopeApi on LeaderboardScope {
  /// Scope value accepted by `GET /leaderboard?scope=`.
  String get apiName => switch (this) {
    LeaderboardScope.country => 'COUNTRY',
    LeaderboardScope.province => 'PROVINCE',
  };
}

/// One ranked entry from `GET /leaderboard`.
class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.userId,
    required this.score,
    this.rankingTier,
    this.displayName,
    this.avatarUrl,
    this.snapshotDate,
  });

  final int rank;
  final String userId;
  final int score;
  final String? rankingTier;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? snapshotDate;

  String get fallbackName =>
      (displayName ?? '').trim().isEmpty ? 'Learner' : displayName!.trim();

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) => LeaderboardRow(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    userId: json['userId']?.toString() ?? '',
    score: (json['score'] as num?)?.toInt() ?? 0,
    rankingTier: json['rankingTier'] as String?,
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    snapshotDate: DateTime.tryParse(json['snapshotDate']?.toString() ?? ''),
  );
}
