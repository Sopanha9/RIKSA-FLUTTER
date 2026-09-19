import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/data/public_profile.dart';
import '../../userProfile/providers/public_profile_provider.dart';
import '../data/blog_api.dart';
import '../data/blog_models.dart';

final blogApiProvider = Provider<BlogApi>((ref) {
  return BlogApi(ref.watch(dioClientProvider));
});

final blogCategoriesProvider = FutureProvider<List<BlogCategory>>(
  (ref) => ref.watch(blogApiProvider).categories(),
);

/// How many of the signed-in author's posts are still waiting on a
/// moderator.
///
/// A pending post is missing from every public feed, so this count is what
/// tells the author their writing did not disappear. Only the total is
/// needed, so the request asks for a single row. Failures resolve to zero:
/// a missing badge is better than an error where the blog list should be.
final pendingBlogPostCountProvider = FutureProvider<int>((ref) async {
  try {
    final page = await ref
        .watch(blogApiProvider)
        .myPosts(status: BlogStatus.pending, size: 1);
    return page.totalElements;
  } catch (_) {
    return 0;
  }
});

/// Category for a post, resolved from the already-loaded category list.
///
/// Returns null while categories are loading or when the id is unknown, so
/// callers can simply omit the label instead of showing a placeholder.
final blogCategoryProvider = Provider.family<BlogCategory?, String>((ref, id) {
  final categories = ref.watch(blogCategoriesProvider).value;
  if (categories == null || id.isEmpty) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});

/// Public identity of a post author, keyed by `authorId`.
///
/// The blog endpoints only return an author id, so the timeline resolves
/// names and avatars from `GET /profiles/{id}`. Each id is fetched once and
/// cached for the session; failures resolve to null so a row still renders.
final blogAuthorProvider = FutureProvider.family<PublicProfile?, String>((
  ref,
  authorId,
) async {
  if (authorId.trim().isEmpty) return null;
  try {
    return await ref.watch(publicProfileRepositoryProvider).fetch(authorId);
  } catch (_) {
    return null;
  }
});

sealed class BlogFeedState {
  const BlogFeedState();
}

class BlogFeedLoading extends BlogFeedState {
  const BlogFeedLoading();
}

class BlogFeedLoaded extends BlogFeedState {
  const BlogFeedLoaded({
    required this.posts,
    required this.page,
    required this.totalPages,
    this.categoryId,
    this.isLoadingMore = false,
    this.loadedAt,
  });

  final List<BlogPost> posts;
  final int page;
  final int totalPages;
  final String? categoryId;
  final bool isLoadingMore;

  /// When this list came back from the server, used to decide whether
  /// reopening the blog is worth a refetch. Null on states built by tests,
  /// which opt out of the staleness refresh.
  final DateTime? loadedAt;

  bool get hasMore => page + 1 < totalPages;
}

class BlogFeedError extends BlogFeedState {
  const BlogFeedError(this.message);
  final String message;
}

class BlogFeedNotifier extends Notifier<BlogFeedState> {
  static const int _pageSize = 20;

  @override
  BlogFeedState build() {
    load();
    return const BlogFeedLoading();
  }

  Future<void> load({String? categoryId}) async {
    state = const BlogFeedLoading();
    try {
      final page = await ref
          .read(blogApiProvider)
          .listPosts(categoryId: categoryId, page: 0, size: _pageSize);
      state = BlogFeedLoaded(
        posts: page.content,
        page: page.page,
        totalPages: page.totalPages,
        categoryId: categoryId,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      state = BlogFeedError(_msg(e));
    }
  }

  /// Refetches when the list on screen is older than [maxAge].
  ///
  /// The feed is loaded once and then kept for the life of the app, so a post
  /// approved by a moderator after that first fetch would never appear
  /// without a manual pull-to-refresh. Reopening the blog re-asks instead,
  /// while a threshold keeps flipping between tabs from hitting the network
  /// every time.
  Future<void> refreshIfStale({Duration maxAge = const Duration(seconds: 30)}) {
    final current = state;
    if (current is BlogFeedError) return load();
    if (current is! BlogFeedLoaded) return Future.value();
    final loadedAt = current.loadedAt;
    if (loadedAt == null) return Future.value();
    if (DateTime.now().difference(loadedAt) < maxAge) return Future.value();
    return load(categoryId: current.categoryId);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! BlogFeedLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }
    state = BlogFeedLoaded(
      posts: current.posts,
      page: current.page,
      totalPages: current.totalPages,
      categoryId: current.categoryId,
      isLoadingMore: true,
      loadedAt: current.loadedAt,
    );
    try {
      final page = await ref
          .read(blogApiProvider)
          .listPosts(
            categoryId: current.categoryId,
            page: current.page + 1,
            size: _pageSize,
          );
      state = BlogFeedLoaded(
        posts: [...current.posts, ...page.content],
        page: page.page,
        totalPages: page.totalPages,
        categoryId: current.categoryId,
        loadedAt: current.loadedAt,
      );
    } catch (_) {
      state = BlogFeedLoaded(
        posts: current.posts,
        page: current.page,
        totalPages: current.totalPages,
        categoryId: current.categoryId,
        loadedAt: current.loadedAt,
      );
    }
  }

  /// Replaces a cached post with a fresher copy, e.g. after the detail
  /// screen liked it. No-op when the post is not in the loaded page.
  void applyUpdate(BlogPost updated) {
    final current = state;
    if (current is! BlogFeedLoaded) return;
    if (!current.posts.any((post) => post.id == updated.id)) return;
    state = BlogFeedLoaded(
      posts: [
        for (final post in current.posts)
          if (post.id == updated.id) updated else post,
      ],
      page: current.page,
      totalPages: current.totalPages,
      categoryId: current.categoryId,
      isLoadingMore: current.isLoadingMore,
      loadedAt: current.loadedAt,
    );
  }

  /// Drops a post the author deleted, so the timeline does not keep showing
  /// something the server no longer has.
  void removePost(String postId) {
    final current = state;
    if (current is! BlogFeedLoaded) return;
    if (!current.posts.any((post) => post.id == postId)) return;
    state = BlogFeedLoaded(
      posts: [
        for (final post in current.posts)
          if (post.id != postId) post,
      ],
      page: current.page,
      totalPages: current.totalPages,
      categoryId: current.categoryId,
      isLoadingMore: current.isLoadingMore,
      loadedAt: current.loadedAt,
    );
  }

  Future<void> toggleLike(String postId) async {
    final current = state;
    if (current is! BlogFeedLoaded) return;
    try {
      final updated = await ref.read(blogApiProvider).toggleLike(postId);
      state = BlogFeedLoaded(
        posts: [
          for (final post in current.posts)
            if (post.id == postId) updated else post,
        ],
        page: current.page,
        totalPages: current.totalPages,
        categoryId: current.categoryId,
        loadedAt: current.loadedAt,
      );
    } catch (_) {
      // Keep the cached list on failure.
    }
  }

  String _msg(Object e) {
    if (e is DioException) return dioErrorMessage(e);
    return 'Something went wrong';
  }
}

final blogFeedProvider = NotifierProvider<BlogFeedNotifier, BlogFeedState>(
  BlogFeedNotifier.new,
);
