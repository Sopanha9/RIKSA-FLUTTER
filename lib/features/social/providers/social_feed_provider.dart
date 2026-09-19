import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';

final socialApiProvider = Provider<SocialApi>((ref) {
  return SocialApi(ref.watch(dioClientProvider));
});

final communityStreakProvider = FutureProvider<CommunityStreak>((ref) async {
  final streak = await ref.watch(socialApiProvider).streak();
  if (streak.lastTrackedDate != null ||
      (streak.activityDates?.isNotEmpty ?? false)) {
    return streak;
  }

  // The streak summary endpoint currently omits dates. Use real XP activity as
  // a non-blocking history fallback until the endpoint exposes them directly.
  try {
    final activity = await ref.watch(profileApiProvider).xpActivity(limit: 50);
    return streak.withActivityDates(
      activity.activities.map((item) => item.createdAt).whereType<DateTime>(),
    );
  } on Object {
    return streak;
  }
});

final userPostsProvider = FutureProvider.family<SocialFeedPage, String>((
  ref,
  userId,
) {
  return ref.watch(socialApiProvider).feed(authorId: userId, limit: 50);
});

sealed class SocialFeedState {
  const SocialFeedState();
}

class SocialFeedLoading extends SocialFeedState {
  const SocialFeedLoading();
}

class SocialFeedLoaded extends SocialFeedState {
  const SocialFeedLoaded({
    required this.categories,
    required this.posts,
    required this.hasNextPage,
    this.endCursor,
    this.selectedCategoryId,
    this.isLoadingMore = false,
  });

  final List<SocialCategory> categories;
  final List<SocialPost> posts;
  final bool hasNextPage;
  final String? endCursor;
  final String? selectedCategoryId;
  final bool isLoadingMore;

  SocialFeedLoaded copyWith({
    List<SocialCategory>? categories,
    List<SocialPost>? posts,
    bool? hasNextPage,
    String? endCursor,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool? isLoadingMore,
  }) => SocialFeedLoaded(
    categories: categories ?? this.categories,
    posts: posts ?? this.posts,
    hasNextPage: hasNextPage ?? this.hasNextPage,
    endCursor: endCursor ?? this.endCursor,
    selectedCategoryId: clearCategory
        ? null
        : selectedCategoryId ?? this.selectedCategoryId,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class SocialFeedFailure extends SocialFeedState {
  const SocialFeedFailure(this.message);

  final String message;
}

class SocialFeedNotifier extends Notifier<SocialFeedState> {
  static const _pageSize = 20;

  @override
  SocialFeedState build() {
    unawaited(load());
    return const SocialFeedLoading();
  }

  Future<void> load({String? categoryId}) async {
    state = const SocialFeedLoading();
    try {
      final api = ref.read(socialApiProvider);
      final results = await Future.wait<Object>([
        api.categories(),
        api.feed(categoryId: categoryId, limit: _pageSize),
      ]);
      final categories = results[0] as List<SocialCategory>;
      final page = results[1] as SocialFeedPage;
      state = SocialFeedLoaded(
        categories: categories,
        posts: page.posts,
        hasNextPage: page.hasNextPage,
        endCursor: page.endCursor,
        selectedCategoryId: categoryId,
      );
    } catch (error) {
      state = SocialFeedFailure(_message(error));
    }
  }

  Future<void> selectCategory(String? categoryId) =>
      load(categoryId: categoryId);

  Future<void> loadMore() async {
    final current = state;
    if (current is! SocialFeedLoaded ||
        current.isLoadingMore ||
        !current.hasNextPage) {
      return;
    }
    state = current.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(socialApiProvider)
          .feed(
            categoryId: current.selectedCategoryId,
            cursor: current.endCursor,
            limit: _pageSize,
          );
      state = current.copyWith(
        posts: [...current.posts, ...page.posts],
        hasNextPage: page.hasNextPage,
        endCursor: page.endCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      state = current.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> toggleReaction(
    String postId, {
    SocialReaction reaction = SocialReaction.upvote,
  }) async {
    final current = state;
    if (current is! SocialFeedLoaded) return false;
    final index = current.posts.indexWhere((post) => post.id == postId);
    if (index < 0) return false;

    final original = current.posts[index];
    final removing = original.myReaction == reaction;
    final optimistic = original.copyWith(
      reactionCount: removing
          ? (original.reactionCount - 1).clamp(0, 1 << 31)
          : original.myReaction == null
          ? original.reactionCount + 1
          : original.reactionCount,
      myReaction: reaction,
      clearReaction: removing,
    );
    state = current.copyWith(posts: _replace(current.posts, optimistic));

    try {
      final updated = await ref
          .read(socialApiProvider)
          .react(postId: postId, reaction: reaction);
      final latest = state;
      if (latest is SocialFeedLoaded) {
        state = latest.copyWith(posts: _replace(latest.posts, updated));
      }
      return true;
    } catch (_) {
      final latest = state;
      if (latest is SocialFeedLoaded) {
        state = latest.copyWith(posts: _replace(latest.posts, original));
      }
      return false;
    }
  }

  /// Publishes a new post. Returns null on success, or a message to show the
  /// author when the server refuses.
  Future<String?> createPost({
    required String title,
    required String content,
    required String categoryId,
    String? mediaUrl,
  }) async {
    final current = state;
    if (current is! SocialFeedLoaded) {
      return 'The community feed is still loading. Try again in a moment.';
    }

    final category = current.categories
        .where((item) => item.id == categoryId)
        .firstOrNull;
    if (category == null) return 'Pick a community for this post.';

    try {
      var categories = current.categories;
      var latest = current;
      if (!category.joined) {
        final joined = await ref
            .read(socialApiProvider)
            .setCategoryJoined(categoryId, joined: true);
        categories = [
          for (final item in categories)
            if (item.id == categoryId) joined else item,
        ];
        latest = current.copyWith(categories: categories);
        state = latest;
      }
      final created = await ref
          .read(socialApiProvider)
          .createPost(
            title: title,
            content: content,
            categoryId: categoryId,
            mediaUrl: mediaUrl,
          );
      state = latest.copyWith(
        categories: categories,
        posts: [created, ...latest.posts],
      );
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  /// Rewrites a post the signed-in user owns. Returns null on success, or a
  /// message to show the author when the server refuses.
  Future<String?> updatePost({
    required String id,
    required String title,
    required String content,
    String? mediaUrl,
  }) async {
    try {
      final updated = await ref
          .read(socialApiProvider)
          .updatePost(
            id: id,
            title: title,
            content: content,
            mediaUrl: mediaUrl,
          );
      syncPost(updated);
      // The author's profile tab reads its own copy of the feed.
      ref.invalidate(userPostsProvider);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  /// Deletes a post the signed-in user owns. Returns null on success, or a
  /// message to show the author when the server refuses.
  Future<String?> deletePost(String id) async {
    try {
      await ref.read(socialApiProvider).deletePost(id);
      removePost(id);
      ref.invalidate(userPostsProvider);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  /// Drops a deleted post from the cached feed.
  void removePost(String postId) {
    final current = state;
    if (current is! SocialFeedLoaded) return;
    if (!current.posts.any((post) => post.id == postId)) return;
    state = current.copyWith(
      posts: [
        for (final post in current.posts)
          if (post.id != postId) post,
      ],
    );
  }

  Future<bool> sharePost(String postId) async {
    try {
      final updated = await ref.read(socialApiProvider).share(postId);
      final current = state;
      if (current is SocialFeedLoaded) {
        state = current.copyWith(posts: _replace(current.posts, updated));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void syncPost(SocialPost post) {
    final current = state;
    if (current is SocialFeedLoaded &&
        current.posts.any((item) => item.id == post.id)) {
      state = current.copyWith(posts: _replace(current.posts, post));
    }
  }

  Future<bool> toggleCategoryMembership(String categoryId) async {
    final current = state;
    if (current is! SocialFeedLoaded) return false;
    final category = current.categories
        .where((item) => item.id == categoryId)
        .firstOrNull;
    if (category == null) return false;
    try {
      final updated = await ref
          .read(socialApiProvider)
          .setCategoryJoined(categoryId, joined: !category.joined);
      final latest = state;
      if (latest is SocialFeedLoaded) {
        state = latest.copyWith(
          categories: [
            for (final item in latest.categories)
              if (item.id == categoryId) updated else item,
          ],
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  List<SocialPost> _replace(List<SocialPost> posts, SocialPost replacement) => [
    for (final post in posts)
      if (post.id == replacement.id) replacement else post,
  ];

  String _message(Object error) {
    if (error is SocialApiException) return error.message;
    if (error is DioException) return dioErrorMessage(error);
    return 'Something went wrong';
  }
}

final socialFeedProvider =
    NotifierProvider<SocialFeedNotifier, SocialFeedState>(
      SocialFeedNotifier.new,
    );
