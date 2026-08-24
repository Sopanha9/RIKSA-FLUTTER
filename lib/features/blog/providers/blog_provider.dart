import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/blog_api.dart';
import '../data/blog_models.dart';

final blogApiProvider = Provider<BlogApi>((ref) {
  return BlogApi(ref.watch(dioClientProvider));
});

final blogCategoriesProvider = FutureProvider<List<BlogCategory>>(
  (ref) => ref.watch(blogApiProvider).categories(),
);

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
  });

  final List<BlogPost> posts;
  final int page;
  final int totalPages;
  final String? categoryId;
  final bool isLoadingMore;

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
      );
    } catch (e) {
      state = BlogFeedError(_msg(e));
    }
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
      );
    } catch (_) {
      state = BlogFeedLoaded(
        posts: current.posts,
        page: current.page,
        totalPages: current.totalPages,
        categoryId: current.categoryId,
      );
    }
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
