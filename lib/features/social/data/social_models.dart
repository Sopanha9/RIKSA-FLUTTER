library;

import 'package:markdown/markdown.dart' as markdown;

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
    this.myRole,
    this.postPermission = CommunityPostPermission.members,
    this.pinnedPostId,
    this.rules = const [],
    this.bannerUrl,
    this.bannerColor,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int memberCount;
  final bool joined;

  /// The viewer's role here; null when they are not a member.
  final CommunityRole? myRole;
  final CommunityPostPermission postPermission;
  final String? pinnedPostId;
  final List<CommunityRule> rules;

  /// A banner photo the owner uploaded.
  final String? bannerUrl;

  /// A #RRGGBB banner colour; null keeps the subject colour.
  final String? bannerColor;

  bool get canModerate => myRole?.canModerate ?? false;
  bool get isOwner => myRole == CommunityRole.owner;

  /// Whether the viewer may start a post here.
  bool get canPost =>
      joined &&
      (postPermission == CommunityPostPermission.members || canModerate);

  factory SocialCategory.fromJson(Map<String, dynamic> json) => SocialCategory(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    iconUrl: json['iconUrl'] as String?,
    memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    joined: json['joined'] as bool? ?? false,
    myRole: CommunityRole.fromWire(json['myRole']),
    postPermission: CommunityPostPermission.fromWire(json['postPermission']),
    pinnedPostId: json['pinnedPostId']?.toString(),
    bannerUrl: json['bannerUrl'] as String?,
    bannerColor: json['bannerColor'] as String?,
    rules: [
      for (final item in (json['rules'] as List?) ?? const [])
        if (item is Map) CommunityRule.fromJson(item.cast<String, dynamic>()),
    ],
  );
}

enum CommunityRole {
  owner('OWNER'),
  moderator('MODERATOR'),
  member('MEMBER');

  const CommunityRole(this.wire);
  final String wire;

  bool get canModerate => this != member;

  static CommunityRole? fromWire(Object? value) {
    for (final role in values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

enum CommunityPostPermission {
  members('MEMBERS'),
  moderators('MODERATORS');

  const CommunityPostPermission(this.wire);
  final String wire;

  static CommunityPostPermission fromWire(Object? value) =>
      value == moderators.wire ? moderators : members;
}

class CommunityRule {
  const CommunityRule({required this.title, this.body});

  final String title;
  final String? body;

  factory CommunityRule.fromJson(Map<String, dynamic> json) => CommunityRule(
    title: json['title'] as String? ?? '',
    body: json['body'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    if (body != null && body!.trim().isNotEmpty) 'body': body,
  };
}

class CommunityMember {
  const CommunityMember({
    required this.user,
    required this.role,
    this.joinedAt,
  });

  final SocialAuthor user;
  final CommunityRole role;
  final DateTime? joinedAt;

  factory CommunityMember.fromJson(Map<String, dynamic> json) =>
      CommunityMember(
        user: SocialAuthor.fromJson(
          (json['user'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
        role: CommunityRole.fromWire(json['role']) ?? CommunityRole.member,
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
      );
}

class CommunityBanEntry {
  const CommunityBanEntry({required this.user, this.reason, this.createdAt});

  final SocialAuthor user;
  final String? reason;
  final DateTime? createdAt;

  factory CommunityBanEntry.fromJson(Map<String, dynamic> json) =>
      CommunityBanEntry(
        user: SocialAuthor.fromJson(
          (json['user'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
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

class SocialPostMedia {
  const SocialPostMedia({required this.url, this.width, this.height});

  final String url;
  final int? width;
  final int? height;

  double? get aspectRatio {
    final mediaWidth = width;
    final mediaHeight = height;
    if (mediaWidth == null || mediaHeight == null || mediaHeight <= 0) {
      return null;
    }
    final ratio = mediaWidth / mediaHeight;
    return ratio.isFinite && ratio > 0 ? ratio : null;
  }

  factory SocialPostMedia.fromJson(Map<String, dynamic> json) =>
      SocialPostMedia(
        url: json['url'] as String? ?? '',
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
      );
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
    List<SocialPostMedia>? media,
    String? mediaUrl,
    this.myReaction,
    this.kind = SocialPostKind.user,
    this.milestone,
  }) : // Named parameters cannot be private, so the formal cannot be used.
       // ignore: prefer_initializing_formals
       _media = media,
       _legacyMediaUrl = mediaUrl;

  final String id;
  final String title;
  final String content;
  final List<SocialPostMedia>? _media;
  final String? _legacyMediaUrl;
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

  List<SocialPostMedia> get media {
    final parsed = _media;
    if (parsed != null) return parsed;
    final legacyUrl = _legacyMediaUrl?.trim();
    return legacyUrl == null || legacyUrl.isEmpty
        ? const <SocialPostMedia>[]
        : <SocialPostMedia>[SocialPostMedia(url: legacyUrl)];
  }

  String? get mediaUrl => _media == null
      ? _legacyMediaUrl
      : (media.isEmpty ? null : media.first.url);
  bool get hasMedia => media.any((item) => item.url.trim().isNotEmpty);
  String get markdownContent => normalizeSocialMarkdown(content);
  String get plainTextPreview => socialMarkdownPreview(content);

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final legacyUrl = json['mediaUrl'] as String?;
    final rawMedia = json['media'];
    final parsedMedia = rawMedia is List
        ? rawMedia
              .whereType<Map>()
              .map(
                (item) =>
                    SocialPostMedia.fromJson(item.cast<String, dynamic>()),
              )
              .where((item) => item.url.trim().isNotEmpty)
              .toList(growable: false)
        : null;
    return SocialPost(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      media: parsedMedia,
      mediaUrl: legacyUrl,
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
  }

  SocialPost copyWith({
    int? reactionCount,
    int? commentCount,
    int? shareCount,
    List<SocialPostMedia>? media,
    SocialReaction? myReaction,
    bool clearReaction = false,
  }) => SocialPost(
    id: id,
    title: title,
    content: content,
    media: media ?? this.media,
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

String socialMarkdownPreview(String value) {
  final source = normalizeSocialMarkdown(value);
  final nodes = markdown.Document().parseLines(source.split('\n'));

  String collect(markdown.Node node) {
    if (node is markdown.Text) return node.text;
    if (node is! markdown.Element) return '';
    if (node.tag == 'img') return '[photo]';

    final children = node.children?.map(collect).join() ?? '';
    if (node.tag == 'li') return '\u2022 ${children.trim()}\n';
    if (node.tag == 'pre') return '${children.trimRight()}\n';
    if (node.tag == 'p' ||
        node.tag == 'blockquote' ||
        RegExp(r'^h[1-6]$').hasMatch(node.tag)) {
      return '${children.trimRight()}\n';
    }
    return children;
  }

  final text = nodes.map(collect).join();
  return text
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'[\t ]+\n'), '\n')
      .replaceAll(RegExp(r'\n[\t ]*\n+'), '\n')
      .trim();
}

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

  SocialComment copyWith({
    SocialReaction? myReaction,
    bool clearReaction = false,
  }) => SocialComment(
    id: id,
    content: content,
    author: author,
    postId: postId,
    parentId: parentId,
    myReaction: clearReaction ? null : myReaction ?? this.myReaction,
    createdAt: createdAt,
    updatedAt: updatedAt,
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
