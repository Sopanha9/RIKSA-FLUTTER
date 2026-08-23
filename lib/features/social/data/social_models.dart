library;

class CommunityStreak {
  const CommunityStreak({
    required this.current,
    required this.highest,
    this.currentMilestoneName,
    this.nextMilestoneName,
    this.daysToNext = 0,
  });

  final int current;
  final int highest;
  final String? currentMilestoneName;
  final String? nextMilestoneName;
  final int daysToNext;

  factory CommunityStreak.fromJson(Map<String, dynamic> json) =>
      CommunityStreak(
        current: (json['currentStreak'] as num?)?.toInt() ?? 0,
        highest: (json['highestStreak'] as num?)?.toInt() ?? 0,
        currentMilestoneName: json['currentMilestoneName'] as String?,
        nextMilestoneName: json['nextMilestoneName'] as String?,
        daysToNext: (json['daysToNext'] as num?)?.toInt() ?? 0,
      );
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
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;

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
  );
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
