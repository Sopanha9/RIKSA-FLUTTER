library;

class CommunityStreak {
  const CommunityStreak({
    required this.current,
    required this.highest,
    this.currentMilestoneName,
    this.nextMilestoneName,
    this.daysToNext = 0,
    this.lastTrackedDate,
    this.activityDates,
  });

  final int current;
  final int highest;
  final String? currentMilestoneName;
  final String? nextMilestoneName;
  final int daysToNext;
  final DateTime? lastTrackedDate;
  final List<DateTime>? activityDates;

  factory CommunityStreak.fromJson(Map<String, dynamic> json) {
    final activityValues =
        json['activityDates'] ?? json['activeDates'] ?? json['streakDates'];
    final activityDates = activityValues is List
        ? activityValues.map(_streakDate).whereType<DateTime>().toList()
        : const <DateTime>[];
    final explicitLastDate = _streakDate(
      json['lastTrackedDate'] ??
          json['lastActivityDate'] ??
          json['lastStreakDate'],
    );
    final latestActivityDate = activityDates.isEmpty
        ? null
        : activityDates.reduce((a, b) => a.isAfter(b) ? a : b);

    return CommunityStreak(
      current: (json['currentStreak'] as num?)?.toInt() ?? 0,
      highest: (json['highestStreak'] as num?)?.toInt() ?? 0,
      currentMilestoneName: json['currentMilestoneName'] as String?,
      nextMilestoneName: json['nextMilestoneName'] as String?,
      daysToNext: (json['daysToNext'] as num?)?.toInt() ?? 0,
      lastTrackedDate: explicitLastDate ?? latestActivityDate,
      activityDates: activityDates,
    );
  }

  CommunityStreak withActivityDates(Iterable<DateTime> dates) {
    final combined = <DateTime>{
      ...(activityDates ?? const <DateTime>[]).map(_normalizeStreakDate),
      ...dates.map(_normalizeStreakDate),
    }.toList()..sort();
    final newest = combined.isEmpty ? null : combined.last;
    final effectiveLastDate = switch ((lastTrackedDate, newest)) {
      (final existing?, final candidate?) =>
        existing.isAfter(candidate) ? existing : candidate,
      (final existing?, null) => existing,
      (null, final candidate?) => candidate,
      (null, null) => null,
    };
    return CommunityStreak(
      current: current,
      highest: highest,
      currentMilestoneName: currentMilestoneName,
      nextMilestoneName: nextMilestoneName,
      daysToNext: daysToNext,
      lastTrackedDate: effectiveLastDate,
      activityDates: combined,
    );
  }
}

DateTime? _streakDate(Object? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  final local = parsed.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _normalizeStreakDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

enum SocialReaction {
  upvote,
  downvote,
  haha,
  love;

  String get wire => name.toUpperCase();

  static SocialReaction? fromWire(String? value) {
    if (value == null) return null;
    for (final reaction in values) {
      if (reaction.wire == value) return reaction;
    }
    return null;
  }
}

class SocialCategory {
  const SocialCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.memberCount,
    required this.joined,
    this.description,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int memberCount;
  final bool joined;

  factory SocialCategory.fromJson(Map<String, dynamic> json) => SocialCategory(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    iconUrl: json['iconUrl'] as String?,
    memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    joined: json['joined'] as bool? ?? false,
  );
}

class SocialAuthor {
  const SocialAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;

  factory SocialAuthor.fromJson(Map<String, dynamic> json) => SocialAuthor(
    id: json['id']?.toString() ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
  );
}

enum SocialPostKind {
  user,
  milestone;

  static SocialPostKind fromWire(Object? value) =>
      value?.toString().toUpperCase() == 'MILESTONE'
      ? SocialPostKind.milestone
      : SocialPostKind.user;
}

enum SocialMilestoneType {
  streak,
  rankUp,
  unitComplete;

  static SocialMilestoneType? fromWire(Object? value) =>
      switch (value?.toString().toUpperCase()) {
        'STREAK' => streak,
        'RANK_UP' => rankUp,
        'UNIT_COMPLETE' => unitComplete,
        _ => null,
      };
}

class SocialMilestone {
  const SocialMilestone({
    required this.type,
    required this.title,
    required this.titleKm,
    this.value,
  });

  final SocialMilestoneType type;
  final String title;
  final String titleKm;
  final int? value;

  String getTitle(String languageCode) =>
      languageCode == 'km' && titleKm.isNotEmpty ? titleKm : title;

  factory SocialMilestone.fromJson(Map<String, dynamic> json) {
    final type = SocialMilestoneType.fromWire(json['type']);
    if (type == null) throw const FormatException('Unknown milestone type');
    return SocialMilestone(
      type: type,
      title: json['title'] as String? ?? '',
      titleKm: json['titleKm'] as String? ?? '',
      value: (json['value'] as num?)?.toInt(),
    );
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.title,
    required this.content,
    required this.reactionCount,
    required this.commentCount,
    required this.shareCount,
    required this.author,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.mediaUrl,
    this.myReaction,
    this.kind = SocialPostKind.user,
    this.milestone,
  });

  final String id;
  final String title;
  final String content;
  final String? mediaUrl;
  final int reactionCount;
  final int commentCount;
  final int shareCount;
  final SocialAuthor author;
  final SocialCategory category;
  final SocialReaction? myReaction;
  final SocialPostKind kind;
  final SocialMilestone? milestone;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;
  String get markdownContent => normalizeSocialMarkdown(content);
  String get plainTextPreview => socialMarkdownPreview(content);

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    mediaUrl: json['mediaUrl'] as String?,
    reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
    commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
    author: SocialAuthor.fromJson(
      (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    category: SocialCategory.fromJson(
      (json['category'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    myReaction: SocialReaction.fromWire(json['myReaction'] as String?),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.now(),
    kind: SocialPostKind.fromWire(json['kind']),
    milestone: (json['milestone'] as Map?) == null
        ? null
        : SocialMilestone.fromJson(
            (json['milestone'] as Map).cast<String, dynamic>(),
          ),
  );

  SocialPost copyWith({
    int? reactionCount,
    int? commentCount,
    int? shareCount,
    SocialReaction? myReaction,
    bool clearReaction = false,
  }) => SocialPost(
    id: id,
    title: title,
    content: content,
    mediaUrl: mediaUrl,
    reactionCount: reactionCount ?? this.reactionCount,
    commentCount: commentCount ?? this.commentCount,
    shareCount: shareCount ?? this.shareCount,
    author: author,
    category: category,
    myReaction: clearReaction ? null : myReaction ?? this.myReaction,
    createdAt: createdAt,
    updatedAt: updatedAt,
    kind: kind,
    milestone: milestone,
  );
}

String normalizeSocialMarkdown(String value) => value
    .replaceAll(r'\r\n', '\n')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\t', '\t');

String socialMarkdownPreview(String value) => normalizeSocialMarkdown(value)
    .replaceAll(RegExp(r'^[ \t]{0,3}#{1,6}[ \t]+', multiLine: true), '')
    .replaceAll(RegExp(r'^[ \t]*[-+][ \t]+', multiLine: true), '• ')
    .replaceAll('**', '')
    .replaceAll('__', '')
    .replaceAll('`', '');

class SocialComment {
  const SocialComment({
    required this.id,
    required this.content,
    required this.author,
    required this.postId,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.myReaction,
  });

  final String id;
  final String content;
  final SocialAuthor author;
  final String postId;
  final String? parentId;
  final SocialReaction? myReaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SocialComment.fromJson(Map<String, dynamic> json) => SocialComment(
    id: json['id']?.toString() ?? '',
    content: json['content'] as String? ?? '',
    author: SocialAuthor.fromJson(
      (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    postId: json['postId']?.toString() ?? '',
    parentId: json['parentId']?.toString(),
    myReaction: SocialReaction.fromWire(json['myReaction'] as String?),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}

class SocialCommentPage {
  const SocialCommentPage({
    required this.comments,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<SocialComment> comments;
  final bool hasNextPage;
  final String? endCursor;

  factory SocialCommentPage.fromJson(Map<String, dynamic> json) {
    final pageInfo =
        (json['pageInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SocialCommentPage(
      comments: ((json['edges'] as List?) ?? const [])
          .map(
            (item) =>
                SocialComment.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
      endCursor: pageInfo['endCursor']?.toString(),
    );
  }
}

class SocialFeedPage {
  const SocialFeedPage({
    required this.posts,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<SocialPost> posts;
  final bool hasNextPage;
  final String? endCursor;

  factory SocialFeedPage.fromJson(Map<String, dynamic> json) {
    final pageInfo =
        (json['pageInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SocialFeedPage(
      posts: ((json['edges'] as List?) ?? const [])
          .map(
            (item) =>
                SocialPost.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
      endCursor: pageInfo['endCursor']?.toString(),
    );
  }
}
