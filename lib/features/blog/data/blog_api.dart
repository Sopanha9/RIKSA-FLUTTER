import 'package:dio/dio.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../auth/data/auth_api.dart';
import 'blog_models.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The two writes only the author may perform on their own post.
enum BlogOwnerAction { edit, delete }

/// Message for a failed author write.
///
/// `403` and `404` are the two outcomes a reader can act on; `405`/`501` say
/// the deployed backend has not shipped the endpoint yet.
String blogOwnerActionError(
  DioException error,
  BlogOwnerAction action, {
  required AppLocalizations l10n,
}) {
  final editing = action == BlogOwnerAction.edit;
  return switch (error.response?.statusCode) {
    403 => editing ? l10n.blogOwnerEditFailed : l10n.blogOwnerDeleteFailed,
    404 => l10n.blogPostGone,
    405 || 501 => l10n.blogSomethingWentWrong,
    _ => dioErrorMessage(error),
  };
}

/// Wraps the `/api/v1/blog` endpoints plus the GraphQL categories query.
class BlogApi {
  BlogApi(this._client);

  final DioClient _client;

  Future<BlogPage> listPosts({
    String? categoryId,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.dio.get(
      '/blog',
      queryParameters: {'page': page, 'size': size, 'categoryId': ?categoryId},
    );
    return BlogPage.fromJson(jsonMap(res));
  }

  Future<BlogPage> myPosts({
    BlogStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.dio.get(
      '/blog/my-posts',
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null) 'status': status.wire,
      },
    );
    return BlogPage.fromJson(jsonMap(res));
  }

  /// Fetching by id automatically records a view for the current user.
  Future<BlogPost> getPost(String id) async {
    final res = await _client.dio.get('/blog/$id');
    return BlogPost.fromJson(jsonMap(res));
  }

  Future<BlogPost> createPost(BlogPostRequest req) async {
    final res = await _client.dio.post('/blog', data: req.toJson());
    return BlogPost.fromJson(jsonMap(res));
  }

  /// Rewrites a post the signed-in user owns.
  ///
  /// The server decides whether an edit sends an approved post back through
  /// moderation, so callers should read `status` off the returned post rather
  /// than assuming it stayed approved.
  Future<BlogPost> updatePost(String id, BlogPostRequest req) async {
    final res = await _client.dio.put('/blog/$id', data: req.toJson());
    return BlogPost.fromJson(jsonMap(res));
  }

  /// Permanently removes a post the signed-in user owns.
  Future<void> deletePost(String id) async {
    await _client.dio.delete('/blog/$id');
  }

  /// Likes if not liked, unlikes if already liked. Returns the updated post.
  Future<BlogPost> toggleLike(String id) async {
    final res = await _client.dio.post('/blog/$id/like');
    return BlogPost.fromJson(jsonMap(res));
  }

  Future<List<BlogCategory>> categories() async {
    final res = await _client.dio.post(
      '${ApiConfig.baseUrl}/graphql',
      data: {
        'query':
            '{ categories { id name slug description iconUrl memberCount joined } }',
      },
    );
    final data = jsonMap(res);
    final list =
        (data['data'] as Map<String, dynamic>?)?['categories'] as List? ?? [];
    return list
        .map((e) => BlogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
