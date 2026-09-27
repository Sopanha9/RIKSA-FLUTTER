import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';

class _ControlledBlogApi extends BlogApi {
  _ControlledBlogApi()
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final pageRequests = <_PageRequest>[];
  Completer<BlogPost>? likeRequest;

  @override
  Future<BlogPage> listPosts({
    String? categoryId,
    int page = 0,
    int size = 20,
  }) {
    final request = _PageRequest(page, Completer<BlogPage>());
    pageRequests.add(request);
    return request.result.future;
  }

  @override
  Future<BlogPost> toggleLike(String id) => likeRequest!.future;
}

class _PageRequest {
  const _PageRequest(this.page, this.result);

  final int page;
  final Completer<BlogPage> result;
}

class _SeededBlogFeedNotifier extends BlogFeedNotifier {
  @override
  BlogFeedState build() =>
      BlogFeedLoaded(posts: [_post('first')], page: 0, totalPages: 3);
}

final _first = _post('first');

BlogPost _post(String id, {bool liked = false}) => BlogPost(
  id: id,
  authorId: 'author-1',
  title: 'Post $id',
  content: 'Body',
  status: BlogStatus.approved,
  viewCount: 0,
  likeCount: liked ? 1 : 0,
  categoryId: 'category-1',
  liked: liked,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

BlogPage _page(List<BlogPost> posts, {required int page}) => BlogPage(
  content: posts,
  page: page,
  size: 20,
  totalElements: posts.length,
  totalPages: 3,
);

ProviderContainer _container(_ControlledBlogApi api) {
  return ProviderContainer(
    overrides: [
      blogApiProvider.overrideWithValue(api),
      blogFeedProvider.overrideWith(_SeededBlogFeedNotifier.new),
    ],
  );
}

void main() {
  test('loadMore preserves a completed like update', () async {
    final api = _ControlledBlogApi()..likeRequest = Completer<BlogPost>();
    final container = _container(api);
    addTearDown(container.dispose);
    final notifier = container.read(blogFeedProvider.notifier);

    final loadingMore = notifier.loadMore();
    final liking = notifier.toggleLike(_first.id);
    api.likeRequest!.complete(_post('first', liked: true));
    await liking;
    api.pageRequests.single.result.complete(_page([_post('second')], page: 1));
    await loadingMore;

    final state = container.read(blogFeedProvider) as BlogFeedLoaded;
    expect(state.posts.map((post) => post.id), ['first', 'second']);
    expect(state.posts.first.liked, isTrue);
  });

  test('toggleLike preserves a page that completed first', () async {
    final api = _ControlledBlogApi()..likeRequest = Completer<BlogPost>();
    final container = _container(api);
    addTearDown(container.dispose);
    final notifier = container.read(blogFeedProvider.notifier);

    final loadingMore = notifier.loadMore();
    final liking = notifier.toggleLike(_first.id);
    api.pageRequests.single.result.complete(_page([_post('second')], page: 1));
    await loadingMore;
    api.likeRequest!.complete(_post('first', liked: true));
    await liking;

    final state = container.read(blogFeedProvider) as BlogFeedLoaded;
    expect(state.posts.map((post) => post.id), ['first', 'second']);
    expect(state.posts.first.liked, isTrue);
    expect(state.page, 1);
  });
}
