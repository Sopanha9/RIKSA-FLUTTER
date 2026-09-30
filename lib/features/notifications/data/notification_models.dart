/// What happened. Unknown server values fall back to [other] so a newer
/// backend never breaks the inbox.
enum NotificationKind {
  postReaction,
  commentReaction,
  postComment,
  commentReply,
  blogLike,
  blogApproved,
  blogRejected,
  other;

  static NotificationKind fromServer(String? value) => switch (value) {
    'POST_REACTION' => postReaction,
    'COMMENT_REACTION' => commentReaction,
    'POST_COMMENT' => postComment,
    'COMMENT_REPLY' => commentReply,
    'BLOG_LIKE' => blogLike,
    'BLOG_APPROVED' => blogApproved,
    'BLOG_REJECTED' => blogRejected,
    _ => other,
  };
}

class NotificationActor {
  const NotificationActor({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) =>
      NotificationActor(
        id: json['id'].toString(),
        username: json['username'] as String? ?? '',
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  String get name {
    final display = displayName?.trim();
    return display == null || display.isEmpty ? username : display;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.targetType,
    required this.targetId,
    required this.read,
    required this.createdAt,
    this.actor,
    this.postId,
    this.preview,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    return AppNotification(
      id: json['id'].toString(),
      kind: NotificationKind.fromServer(json['type'] as String?),
      actor: actor is Map
          ? NotificationActor.fromJson(actor.cast<String, dynamic>())
          : null,
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId']?.toString() ?? '',
      postId: json['postId']?.toString(),
      preview: json['preview'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final NotificationKind kind;

  /// Null for a moderator's review.
  final NotificationActor? actor;

  /// POST, COMMENT or BLOG.
  final String targetType;
  final String targetId;

  /// The community post to open for post and comment activity.
  final String? postId;
  final String? preview;
  final bool read;
  final DateTime createdAt;

  /// Where tapping the row goes, or null when there's nothing to open.
  String? get location {
    if (targetType == 'BLOG' && targetId.isNotEmpty) return '/blog/$targetId';
    final post = postId;
    if (post != null && post.isNotEmpty) return '/community/posts/$post';
    return null;
  }

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    actor: actor,
    targetType: targetType,
    targetId: targetId,
    postId: postId,
    preview: preview,
    read: true,
    createdAt: createdAt,
  );
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        items: [
          for (final item in (json['items'] as List? ?? const []))
            if (item is Map)
              AppNotification.fromJson(item.cast<String, dynamic>()),
        ],
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        nextCursor: json['nextCursor'] as String?,
      );

  final List<AppNotification> items;
  final int unreadCount;
  final String? nextCursor;
}
