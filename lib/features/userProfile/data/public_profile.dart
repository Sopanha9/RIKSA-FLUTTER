library;

/// Public-only profile data returned by `GET /profiles/{userId}`.
///
/// This model intentionally has no email, phone, gender, account-verification,
/// role, suspension, or private gamification activity fields.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isVerified,
    required this.totalXp,
    required this.currentTier,
    required this.achievements,
    this.avatarUrl,
    this.bio,
    this.currentTierIcon,
    this.rank,
    this.coverUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final int totalXp;
  final String currentTier;
  final String? currentTierIcon;
  final List<PublicProfileAchievement> achievements;
  final PublicProfileRank? rank;
  final String? coverUrl;

  String get preferredName =>
      displayName.trim().isEmpty ? username.trim() : displayName.trim();

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final user = _stringMap(json['user']);
    final gamification = _stringMap(json['gamification']);
    final achievementValues = json['achievements'];
    final achievements = achievementValues is List
        ? achievementValues
              .whereType<Map>()
              .map(
                (value) => PublicProfileAchievement.fromJson(
                  value.cast<String, dynamic>(),
                ),
              )
              .where((value) => value.id.isNotEmpty && value.name.isNotEmpty)
              .toList(growable: false)
        : const <PublicProfileAchievement>[];
    final rankJson = _stringMapOrNull(json['rank']);
    final rank = rankJson == null ? null : PublicProfileRank.fromJson(rankJson);
    final tier = _nonBlankString(gamification['currentTier']);

    return PublicProfile(
      id: user['id']?.toString() ?? '',
      username: _string(user['username']),
      displayName: _string(user['displayName']),
      avatarUrl: _nonBlankString(user['avatarUrl']),
      bio: _nonBlankString(user['bio']),
      isVerified: user['isVerified'] == true,
      totalXp: _int(gamification['totalXp']) ?? 0,
      currentTier: tier ?? 'STARTER',
      currentTierIcon: _nonBlankString(gamification['currentTierIcon']),
      achievements: achievements,
      rank: rank?.hasRank == true ? rank : null,
      coverUrl: _nonBlankString(json['coverUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'isVerified': isVerified,
    },
    'gamification': {
      'totalXp': totalXp,
      'currentTier': currentTier,
      'currentTierIcon': currentTierIcon,
    },
    'achievements': achievements.map((value) => value.toJson()).toList(),
    'rank': rank?.toJson(),
    'coverUrl': coverUrl,
  };
}

class PublicProfileAchievement {
  const PublicProfileAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    this.iconUrl,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String rarity;
  final DateTime? unlockedAt;

  factory PublicProfileAchievement.fromJson(Map<String, dynamic> json) {
    return PublicProfileAchievement(
      id: json['id']?.toString() ?? '',
      name: _string(json['name']),
      description: _string(json['description']),
      iconUrl: _nonBlankString(json['iconUrl']),
      rarity: _nonBlankString(json['rarity']) ?? 'COMMON',
      unlockedAt: DateTime.tryParse(json['unlockedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'rarity': rarity,
    'unlockedAt': unlockedAt?.toUtc().toIso8601String(),
  };
}

class PublicProfileRank {
  const PublicProfileRank({this.countryRank, this.provinceRank});

  final int? countryRank;
  final int? provinceRank;

  bool get hasRank => countryRank != null || provinceRank != null;

  factory PublicProfileRank.fromJson(Map<String, dynamic> json) =>
      PublicProfileRank(
        countryRank: _int(json['countryRank']),
        provinceRank: _int(json['provinceRank']),
      );

  Map<String, dynamic> toJson() => {
    'countryRank': countryRank,
    'provinceRank': provinceRank,
  };
}

Map<String, dynamic> _stringMap(Object? value) =>
    _stringMapOrNull(value) ?? const <String, dynamic>{};

Map<String, dynamic>? _stringMapOrNull(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : null;

String _string(Object? value) => value is String ? value : '';

String? _nonBlankString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _int(Object? value) => value is num ? value.toInt() : null;
