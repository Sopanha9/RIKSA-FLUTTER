import 'package:dio/dio.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_api.dart';
import 'blog_models.dart';

/// The two writes only the author may perform on their own post.
enum BlogOwnerAction { edit, delete }

/// Message for a failed author write.
///
/// `403` and `404` are the two outcomes a reader can act on; `405`/`501` say
/// the deployed backend has not shipped the endpoint yet.
String blogOwnerActionError(DioException error, BlogOwnerAction action) {
  final gerund = action == BlogOwnerAction.edit ? 'Editing' : 'Deleting';
  final verb = action == BlogOwnerAction.edit ? 'edit' : 'delete';
  return switch (error.response?.statusCode) {
    403 => 'You can only $verb your own posts',
    404 => 'This post no longer exists',
    405 || 501 => '$gerund is not available on this server yet',
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
      queryParameters: {
        'page': page,
        'size': size,
        'categoryId': ?categoryId,
      },
    );
    return BlogPage.fromJson(res.data as Map<String, dynamic>);
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
    return BlogPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetching by id automatically records a view for the current user.
  Future<BlogPost> getPost(String id) async {
    final res = await _client.dio.get('/blog/$id');
    return BlogPost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BlogPost> createPost(BlogPostRequest req) async {
    final res = await _client.dio.post('/blog', data: req.toJson());
    return BlogPost.fromJson(res.data as Map<String, dynamic>);
  }

  /// Rewrites a post the signed-in user owns.
  ///
  /// The server decides whether an edit sends an approved post back through
  /// moderation, so callers should read `status` off the returned post rather
  /// than assuming it stayed approved.
  Future<BlogPost> updatePost(String id, BlogPostRequest req) async {
    final res = await _client.dio.put('/blog/$id', data: req.toJson());
    return BlogPost.fromJson(res.data as Map<String, dynamic>);
  }

  /// Permanently removes a post the signed-in user owns.
  Future<void> deletePost(String id) async {
    await _client.dio.delete('/blog/$id');
  }

  /// Likes if not liked, unlikes if already liked. Returns the updated post.
  Future<BlogPost> toggleLike(String id) async {
    final res = await _client.dio.post('/blog/$id/like');
    return BlogPost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<BlogCategory>> categories() async {
    final res = await _client.dio.post(
      '${ApiConfig.baseUrl}/graphql',
      data: {
        'query':
            '{ categories { id name slug description iconUrl memberCount joined } }',
      },
    );
    final data = res.data as Map<String, dynamic>;
    final list =
        (data['data'] as Map<String, dynamic>?)?['categories'] as List? ?? [];
    return list
        .map((e) => BlogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
