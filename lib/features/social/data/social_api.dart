import 'package:dio/dio.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../../core/network/moderation_error.dart';
import '../../auth/data/auth_api.dart';
import 'social_models.dart';

class SocialApiException implements Exception {
  const SocialApiException(this.message, {this.moderationRejection});

  final String message;

  /// Structured moderation details when the server rejected content.
  ///
  /// Kept separate from [message] so composers can localize it. Comment
  /// composers can use the same field in Wave 2.
  final ModerationRejection? moderationRejection;

  @override
  String toString() => message;
}

class SocialCommentThread {
  const SocialCommentThread({
    required this.root,
    required this.replies,
    required this.repliesHaveNextPage,
    this.repliesEndCursor,
  });

  final SocialComment root;
  final List<SocialComment> replies;
  final bool repliesHaveNextPage;
  final String? repliesEndCursor;
}

class SocialCommentThreadPage {
  const SocialCommentThreadPage({
    required this.threads,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<SocialCommentThread> threads;
  final bool hasNextPage;
  final String? endCursor;
}

class SocialCommentReplyPage {
  const SocialCommentReplyPage({
    required this.replies,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<SocialComment> replies;
  final bool hasNextPage;
  final String? endCursor;
}

/// Typed access to the social module's GraphQL contract.
class SocialApi {
  SocialApi(this._client);

  final DioClient _client;
  final Map<String, SocialCommentThreadPage> _threadPageCache = {};

  static const _postFields = r'''
    id title content mediaUrl media { url width height } reactionCount commentCount shareCount myReaction
    kind milestone { type title titleKm value }
    createdAt updatedAt
    author { id username displayName avatarUrl }
    category { id name slug description iconUrl memberCount joined }
  ''';

  static const _commentFields = r'''
    id content postId parentId myReaction createdAt updatedAt
    author { id username displayName avatarUrl }
  ''';

  Future<CommunityStreak> streak() async {
    final response = await _client.dio.get('/gamification/streak');
    return CommunityStreak.fromJson(jsonMap(response));
  }

  Future<List<SocialCategory>> categories() async {
    final data = await _query(r'''
      query Categories {
        categories { id name slug description iconUrl memberCount joined }
      }
    ''');
    return ((data['categories'] as List?) ?? const [])
        .map(
          (item) =>
              SocialCategory.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await _query(
      '''
      query Feed(\$categoryId: UUID, \$authorId: UUID, \$cursor: UUID, \$limit: Int!) {
        feed(categoryId: \$categoryId, authorId: \$authorId, cursor: \$cursor, limit: \$limit) {
          edges { $_postFields }
          pageInfo { hasNextPage endCursor }
        }
      }
      ''',
      variables: {
        'categoryId': categoryId,
        'authorId': authorId,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return SocialFeedPage.fromJson(
      (data['feed'] as Map).cast<String, dynamic>(),
    );
  }

  Future<SocialPost> post(String id) async {
    final data = await _query(
      '''
      query Post(\$id: UUID!) {
        post(id: \$id) { $_postFields }
      }
      ''',
      variables: {'id': id},
    );
    final post = data['post'];
    if (post is! Map) {
      throw const SocialApiException('This post is no longer available.');
    }
    return SocialPost.fromJson(post.cast<String, dynamic>());
  }

  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async {
    final cacheKey = _commentPageKey(postId, cursor, limit);
    final data = await _query(
      '''
      query Comments(\$postId: UUID!, \$cursor: UUID, \$limit: Int!) {
        comments(postId: \$postId, cursor: \$cursor, limit: \$limit) {
          edges {
            $_commentFields
            replies(limit: 5) {
              edges { $_commentFields }
              pageInfo { hasNextPage endCursor }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
      ''',
      variables: {'postId': postId, 'cursor': cursor, 'limit': limit},
    );
    final threadPage = _threadPageFromJson(
      (data['comments'] as Map).cast<String, dynamic>(),
    );
    _threadPageCache[cacheKey] = threadPage;
    return SocialCommentPage(
      comments: [for (final thread in threadPage.threads) thread.root],
      hasNextPage: threadPage.hasNextPage,
      endCursor: threadPage.endCursor,
    );
  }

  Future<SocialComment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final data = await _query(
      '''
      mutation CreateComment(\$input: CreateCommentInput!) {
        createComment(input: \$input) { $_commentFields }
      }
      ''',
      variables: {
        'input': {'postId': postId, 'content': content, 'parentId': ?parentId},
      },
    );
    return SocialComment.fromJson(
      (data['createComment'] as Map).cast<String, dynamic>(),
    );
  }

  Future<SocialPost> react({
    required String postId,
    required SocialReaction reaction,
  }) async {
    final data = await _query(
      '''
      mutation React(\$postId: UUID!, \$type: ReactionType!) {
        react(input: { postId: \$postId, type: \$type }) { $_postFields }
      }
      ''',
      variables: {'postId': postId, 'type': reaction.wire},
    );
    return SocialPost.fromJson((data['react'] as Map).cast<String, dynamic>());
  }

  /// Fetches root comments and each root's first five replies together.
  Future<SocialCommentThreadPage> commentThreads({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async {
    final cacheKey = _commentPageKey(postId, cursor, limit);
    final page = await comments(postId: postId, cursor: cursor, limit: limit);
    return _threadPageCache.remove(cacheKey) ?? _threadPageFromFlatPage(page);
  }

  /// Loads the next replies page for one root by scanning the post's root
  /// comment connection until that root is found. The schema has no
  /// `comment(id:)` query, so replies can only be selected from a root edge.
  Future<SocialCommentReplyPage> commentReplies({
    required String postId,
    required String commentId,
    required String? cursor,
    int limit = 10,
  }) async {
    String? rootCursor;
    final seenRootCursors = <String>{};
    while (true) {
      final data = await _query(
        '''
        query CommentReplies(\$postId: UUID!, \$rootCursor: UUID, \$rootLimit: Int!, \$replyCursor: UUID, \$replyLimit: Int!) {
          comments(postId: \$postId, cursor: \$rootCursor, limit: \$rootLimit) {
            edges {
              id
              replies(cursor: \$replyCursor, limit: \$replyLimit) {
                edges { $_commentFields }
                pageInfo { hasNextPage endCursor }
              }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
        ''',
        variables: {
          'postId': postId,
          'rootCursor': rootCursor,
          'rootLimit': 20,
          'replyCursor': cursor,
          'replyLimit': limit,
        },
      );
      final connection = (data['comments'] as Map).cast<String, dynamic>();
      final roots = (connection['edges'] as List?) ?? const [];
      for (final rootValue in roots) {
        final root = (rootValue as Map).cast<String, dynamic>();
        if (root['id']?.toString() == commentId) {
          return _replyPageFromJson(
            (root['replies'] as Map).cast<String, dynamic>(),
          );
        }
      }
      final pageInfo =
          (connection['pageInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (pageInfo['hasNextPage'] != true) {
        throw const SocialApiException('This comment is no longer available.');
      }
      rootCursor = pageInfo['endCursor']?.toString();
      if (rootCursor == null ||
          rootCursor.isEmpty ||
          !seenRootCursors.add(rootCursor)) {
        throw const SocialApiException('This comment is no longer available.');
      }
    }
  }

  SocialCommentThread _threadFromJson(Map<String, dynamic> json) {
    final repliesConnection =
        (json['replies'] as Map?)?.cast<String, dynamic>() ?? const {};
    final repliesPage = _replyPageFromJson(repliesConnection);
    return SocialCommentThread(
      root: SocialComment.fromJson(json),
      replies: repliesPage.replies,
      repliesHaveNextPage: repliesPage.hasNextPage,
      repliesEndCursor: repliesPage.endCursor,
    );
  }

  SocialCommentThreadPage _threadPageFromJson(Map<String, dynamic> json) {
    final pageInfo =
        (json['pageInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SocialCommentThreadPage(
      threads: [
        for (final edge in (json['edges'] as List?) ?? const [])
          _threadFromJson((edge as Map).cast<String, dynamic>()),
      ],
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
      endCursor: pageInfo['endCursor']?.toString(),
    );
  }

  SocialCommentThreadPage _threadPageFromFlatPage(SocialCommentPage page) {
    final byId = {for (final comment in page.comments) comment.id: comment};
    final roots = page.comments.where(
      (comment) =>
          comment.parentId == null || !byId.containsKey(comment.parentId),
    );
    return SocialCommentThreadPage(
      threads: [
        for (final root in roots)
          SocialCommentThread(
            root: root,
            replies: page.comments
                .where((comment) => comment.parentId == root.id)
                .toList(),
            repliesHaveNextPage: false,
          ),
      ],
      hasNextPage: page.hasNextPage,
      endCursor: page.endCursor,
    );
  }

  String _commentPageKey(String postId, String? cursor, int limit) =>
      '$postId|${cursor ?? ''}|$limit';

  SocialCommentReplyPage _replyPageFromJson(Map<String, dynamic> json) {
    final pageInfo =
        (json['pageInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SocialCommentReplyPage(
      replies: ((json['edges'] as List?) ?? const [])
          .map(
            (edge) =>
                SocialComment.fromJson((edge as Map).cast<String, dynamic>()),
          )
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
      endCursor: pageInfo['endCursor']?.toString(),
    );
  }

  /// Toggles a comment reaction through the shared `react` mutation.
  ///
  /// The API removes a reaction by receiving the same type again, so a null
  /// desired reaction still sends LOVE. This is used when toggling a liked
  /// comment off.
  Future<SocialPost> reactToComment({
    required String commentId,
    required SocialReaction? reaction,
  }) async {
    final data = await _query(
      '''
      mutation ReactToComment(\$commentId: UUID!, \$type: ReactionType!) {
        react(input: { commentId: \$commentId, type: \$type }) { $_postFields }
      }
      ''',
      variables: {
        'commentId': commentId,
        'type': (reaction ?? SocialReaction.love).wire,
      },
    );
    return SocialPost.fromJson((data['react'] as Map).cast<String, dynamic>());
  }

  Future<SocialPost> createPost({
    required String title,
    required String content,
    required String categoryId,
    String? mediaUrl,
  }) => createPostWithMedia(
    title: title,
    content: content,
    categoryId: categoryId,
    media: mediaUrl == null || mediaUrl.trim().isEmpty
        ? const []
        : [SocialPostMedia(url: mediaUrl)],
  );

  /// Creates a post with an ordered set of uploaded photos.
  Future<SocialPost> createPostWithMedia({
    required String title,
    required String content,
    required String categoryId,
    List<SocialPostMedia> media = const [],
  }) async {
    final data = await _query(
      '''
      mutation CreatePost(\$input: CreatePostInput!) {
        createPost(input: \$input) { $_postFields }
      }
      ''',
      variables: {
        'input': {
          'title': title,
          'content': content,
          'categoryId': categoryId,
          'media': [for (final item in media) _mediaInput(item)],
        },
      },
    );
    return SocialPost.fromJson(
      (data['createPost'] as Map).cast<String, dynamic>(),
    );
  }

  /// Rewrites a post the signed-in user owns (`updatePost`, owner only).
  ///
  /// `UpdatePostInput` is assumed to mirror `CreatePostInput` plus the post
  /// id; the category stays put because moving a post would also have to
  /// satisfy the join-before-posting rule.
  Future<SocialPost> updatePost({
    required String id,
    required String title,
    required String content,
    String? mediaUrl,
  }) => updatePostWithMedia(
    id: id,
    title: title,
    content: content,
    media: mediaUrl == null
        ? null
        : mediaUrl.trim().isEmpty
        ? const []
        : [SocialPostMedia(url: mediaUrl)],
  );

  /// Updates a post. A null media list leaves photos unchanged; an empty
  /// list clears them.
  Future<SocialPost> updatePostWithMedia({
    required String id,
    required String title,
    required String content,
    List<SocialPostMedia>? media,
  }) async {
    final data = await _query(
      '''
      mutation UpdatePost(\$input: UpdatePostInput!) {
        updatePost(input: \$input) { $_postFields }
      }
      ''',
      variables: {
        'input': {
          'id': id,
          'title': title,
          'content': content,
          // Null leaves photos unchanged; an empty list clears them.
          if (media != null)
            'media': [for (final item in media) _mediaInput(item)],
        },
      },
    );
    return SocialPost.fromJson(
      (data['updatePost'] as Map).cast<String, dynamic>(),
    );
  }

  /// Uploads an image and returns its URL and server-measured dimensions.
  ///
  /// The API keeps the bytes and hands back a link; nothing else in the app
  /// needs to know where they live. Throws [SocialApiException] with the
  /// server's reason when the file is rejected.
  Future<SocialPostMedia> uploadMedia(
    String filePath, {
    String? filename,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _client.dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/media',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      final result = jsonMap(response);
      final url = result['url'];
      if (url is! String || url.isEmpty) {
        throw const SocialApiException('The image upload returned no link.');
      }
      return SocialPostMedia(
        url: url,
        width: (result['width'] as num?)?.toInt(),
        height: (result['height'] as num?)?.toInt(),
      );
    } on DioException catch (error) {
      throw SocialApiException(dioErrorMessage(error));
    }
  }

  Map<String, Object> _mediaInput(SocialPostMedia media) => {
    'url': media.url,
    if (media.width != null) 'width': media.width!,
    if (media.height != null) 'height': media.height!,
  };

  /// Removes a post the signed-in user owns (`deletePost`, owner only).
  Future<void> deletePost(String id) async {
    final data = await _query(
      r'''
      mutation DeletePost($id: UUID!) { deletePost(id: $id) }
      ''',
      variables: {'id': id},
    );
    if (data['deletePost'] == false) {
      throw const SocialApiException('This post could not be deleted.');
    }
  }

  /// Removes a comment the signed-in user owns (`deleteComment`, owner only).
  Future<void> deleteComment(String id) async {
    final data = await _query(
      r'''
      mutation DeleteComment($id: UUID!) { deleteComment(id: $id) }
      ''',
      variables: {'id': id},
    );
    if (data['deleteComment'] == false) {
      throw const SocialApiException('This comment could not be deleted.');
    }
  }

  Future<SocialPost> share(String postId) async {
    final data = await _query(
      '''
      mutation Share(\$postId: UUID!) {
        sharePost(input: { postId: \$postId, platform: COPY_LINK }) {
          $_postFields
        }
      }
      ''',
      variables: {'postId': postId},
    );
    return SocialPost.fromJson(
      (data['sharePost'] as Map).cast<String, dynamic>(),
    );
  }

  Future<SocialCategory> setCategoryJoined(
    String categoryId, {
    required bool joined,
  }) async {
    final field = joined ? 'joinCategory' : 'leaveCategory';
    final data = await _query(
      '''
      mutation CategoryMembership(\$categoryId: UUID!) {
        $field(categoryId: \$categoryId) {
          id name slug description iconUrl memberCount joined
        }
      }
      ''',
      variables: {'categoryId': categoryId},
    );
    return SocialCategory.fromJson(
      (data[field] as Map).cast<String, dynamic>(),
    );
  }

  /// Founds a community owned by the signed-in member, who joins it at once.
  ///
  /// The server cleans every field, generates the slug, and enforces who may
  /// create and how often; its refusal comes back as a [SocialApiException].
  Future<SocialCategory> createCommunity({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    final data = await _query(
      r'''
      mutation CreateCommunity($input: CreateCommunityInput!) {
        createCommunity(input: $input) {
          id name slug description iconUrl memberCount joined
        }
      }
      ''',
      variables: {
        'input': {
          'name': name,
          'description': ?description,
          'iconUrl': ?iconUrl,
        },
      },
    );
    return SocialCategory.fromJson(
      (data['createCommunity'] as Map).cast<String, dynamic>(),
    );
  }

  static const _communityFields = '''
    id name slug description iconUrl memberCount joined
    myRole postPermission pinnedPostId bannerUrl bannerColor
    rules { title body }
  ''';

  /// One community with the viewer's role, its rules and settings.
  Future<SocialCategory?> community(String id) async {
    final data = await _query(
      '''
      query Community(\$id: UUID!) {
        community(id: \$id) { $_communityFields }
      }
      ''',
      variables: {'id': id},
    );
    final json = data['community'];
    return json is Map
        ? SocialCategory.fromJson(json.cast<String, dynamic>())
        : null;
  }

  /// Owner only. Null leaves a field unchanged; [rules] replaces every rule.
  Future<SocialCategory> updateCommunity({
    required String id,
    String? name,
    String? description,
    CommunityPostPermission? postPermission,
    List<CommunityRule>? rules,
    String? iconUrl,
    bool clearIcon = false,
    String? bannerUrl,
    bool clearBanner = false,
    String? bannerColor,
  }) async {
    final data = await _query(
      '''
      mutation UpdateCommunity(\$input: UpdateCommunityInput!) {
        updateCommunity(input: \$input) { $_communityFields }
      }
      ''',
      variables: {
        'input': {
          'id': id,
          'name': ?name,
          'description': ?description,
          'postPermission': ?postPermission?.wire,
          'iconUrl': ?iconUrl,
          if (clearIcon) 'clearIcon': true,
          'bannerUrl': ?bannerUrl,
          if (clearBanner) 'clearBanner': true,
          'bannerColor': ?bannerColor,
          if (rules != null) 'rules': [for (final rule in rules) rule.toJson()],
        },
      },
    );
    return SocialCategory.fromJson(
      (data['updateCommunity'] as Map).cast<String, dynamic>(),
    );
  }

  Future<List<CommunityMember>> communityMembers(
    String categoryId, {
    String? query,
  }) async {
    final data = await _query(
      r'''
      query CommunityMembers($categoryId: UUID!, $query: String) {
        communityMembers(categoryId: $categoryId, query: $query, limit: 100) {
          role joinedAt
          user { id username displayName avatarUrl }
        }
      }
      ''',
      variables: {'categoryId': categoryId, 'query': ?query},
    );
    return [
      for (final item in (data['communityMembers'] as List?) ?? const [])
        CommunityMember.fromJson((item as Map).cast<String, dynamic>()),
    ];
  }

  Future<List<CommunityBanEntry>> communityBans(String categoryId) async {
    final data = await _query(
      r'''
      query CommunityBans($categoryId: UUID!) {
        communityBans(categoryId: $categoryId) {
          reason createdAt
          user { id username displayName avatarUrl }
        }
      }
      ''',
      variables: {'categoryId': categoryId},
    );
    return [
      for (final item in (data['communityBans'] as List?) ?? const [])
        CommunityBanEntry.fromJson((item as Map).cast<String, dynamic>()),
    ];
  }

  Future<void> setCommunityMemberRole(
    String categoryId,
    String userId,
    CommunityRole role,
  ) async {
    await _query(
      r'''
      mutation SetRole($categoryId: UUID!, $userId: UUID!, $role: CommunityRole!) {
        setCommunityMemberRole(categoryId: $categoryId, userId: $userId, role: $role) { role }
      }
      ''',
      variables: {
        'categoryId': categoryId,
        'userId': userId,
        'role': role.wire,
      },
    );
  }

  /// Removes a member; with [ban] they can't join again until unbanned.
  Future<void> removeCommunityMember(
    String categoryId,
    String userId, {
    bool ban = false,
    String? reason,
  }) async {
    await _query(
      r'''
      mutation RemoveMember($categoryId: UUID!, $userId: UUID!, $ban: Boolean, $reason: String) {
        removeCommunityMember(categoryId: $categoryId, userId: $userId, ban: $ban, reason: $reason)
      }
      ''',
      variables: {
        'categoryId': categoryId,
        'userId': userId,
        'ban': ban,
        'reason': ?reason,
      },
    );
  }

  Future<void> unbanCommunityMember(String categoryId, String userId) async {
    await _query(
      r'''
      mutation Unban($categoryId: UUID!, $userId: UUID!) {
        unbanCommunityMember(categoryId: $categoryId, userId: $userId)
      }
      ''',
      variables: {'categoryId': categoryId, 'userId': userId},
    );
  }

  /// Pins [postId] to the top of the community; null unpins.
  Future<SocialCategory> pinCommunityPost(
    String categoryId,
    String? postId,
  ) async {
    final data = await _query(
      '''
      mutation Pin(\$categoryId: UUID!, \$postId: UUID) {
        pinCommunityPost(categoryId: \$categoryId, postId: \$postId) { $_communityFields }
      }
      ''',
      variables: {'categoryId': categoryId, 'postId': postId},
    );
    return SocialCategory.fromJson(
      (data['pinCommunityPost'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Map<String, dynamic>> _query(
    String query, {
    Map<String, dynamic> variables = const {},
  }) async {
    final response = await _client.dio.post(
      '${ApiConfig.baseUrl}/graphql',
      data: {'query': query, 'variables': variables},
    );
    final payload = jsonMap(response);
    final errors = payload['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final first = (errors.first as Map).cast<String, dynamic>();
      throw SocialApiException(
        first['message'] as String? ?? 'The community feed could not load.',
        moderationRejection: fromGraphQlErrors(errors.cast<Object?>()),
      );
    }
    return (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {};
  }
}
