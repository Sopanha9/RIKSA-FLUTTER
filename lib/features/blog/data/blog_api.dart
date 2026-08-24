import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'blog_models.dart';

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

  Future<BlogPost> createPost(CreateBlogPostRequest req) async {
    final res = await _client.dio.post('/blog', data: req.toJson());
    return BlogPost.fromJson(res.data as Map<String, dynamic>);
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
