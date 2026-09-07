import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'social_models.dart';

class SocialApiException implements Exception {
  const SocialApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Typed access to the social module's GraphQL contract.
class SocialApi {
  SocialApi(this._client);

  final DioClient _client;

  static const _postFields = r'''
    id title content mediaUrl reactionCount commentCount shareCount myReaction
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
    return CommunityStreak.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
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
    final data = await _query(
      '''
      query Comments(\$postId: UUID!, \$cursor: UUID, \$limit: Int!) {
        comments(postId: \$postId, cursor: \$cursor, limit: \$limit) {
          edges { $_commentFields }
          pageInfo { hasNextPage endCursor }
        }
      }
      ''',
      variables: {'postId': postId, 'cursor': cursor, 'limit': limit},
    );
    return SocialCommentPage.fromJson(
      (data['comments'] as Map).cast<String, dynamic>(),
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
        'input': {
          'postId': postId,
          'content': content,
          'parentId': ?parentId,
        },
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

  Future<SocialPost> createPost({
    required String title,
    required String content,
    required String categoryId,
  }) async {
    final data = await _query(
      '''
      mutation CreatePost(\$input: CreatePostInput!) {
        createPost(input: \$input) { $_postFields }
      }
      ''',
      variables: {
        'input': {'title': title, 'content': content, 'categoryId': categoryId},
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
  }) async {
    final data = await _query(
      '''
      mutation UpdatePost(\$input: UpdatePostInput!) {
        updatePost(input: \$input) { $_postFields }
      }
      ''',
      variables: {
        'input': {'id': id, 'title': title, 'content': content},
      },
    );
    return SocialPost.fromJson(
      (data['updatePost'] as Map).cast<String, dynamic>(),
    );
  }

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

  Future<Map<String, dynamic>> _query(
    String query, {
    Map<String, dynamic> variables = const {},
  }) async {
    final response = await _client.dio.post(
      '${ApiConfig.baseUrl}/graphql',
      data: {'query': query, 'variables': variables},
    );
    final payload = (response.data as Map).cast<String, dynamic>();
    final errors = payload['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final first = (errors.first as Map).cast<String, dynamic>();
      throw SocialApiException(
        first['message'] as String? ?? 'The community feed could not load.',
      );
    }
    return (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {};
  }
}
