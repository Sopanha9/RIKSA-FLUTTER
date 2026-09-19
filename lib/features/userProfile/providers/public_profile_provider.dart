import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_models.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/public_profile.dart';
import '../data/public_profile_api.dart';

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((
  ref,
) {
  return HttpPublicProfileRepository(ref.watch(dioClientProvider));
});

final publicProfileSocialRepositoryProvider =
    Provider<PublicProfileSocialRepository>((ref) {
      return SocialApiPublicProfileRepository(ref.watch(socialApiProvider));
    });

enum PublicProfileStatus { loading, ready, unavailable, failure }

class PublicProfileState {
  const PublicProfileState({
    this.status = PublicProfileStatus.loading,
    this.profile,
    this.posts = const [],
    this.hasNextPage = false,
    this.endCursor,
    this.isLoadingPosts = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.postsErrorMessage,
    this.paginationErrorMessage,
  });

  final PublicProfileStatus status;
  final PublicProfile? profile;
  final List<SocialPost> posts;
  final bool hasNextPage;
  final String? endCursor;
  final bool isLoadingPosts;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? postsErrorMessage;
  final String? paginationErrorMessage;

  PublicProfileState copyWith({
    PublicProfileStatus? status,
    PublicProfile? profile,
    List<SocialPost>? posts,
    bool? hasNextPage,
    String? endCursor,
    bool clearEndCursor = false,
    bool? isLoadingPosts,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    String? postsErrorMessage,
    bool clearPostsError = false,
    String? paginationErrorMessage,
    bool clearPaginationError = false,
  }) => PublicProfileState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    posts: posts ?? this.posts,
    hasNextPage: hasNextPage ?? this.hasNextPage,
    endCursor: clearEndCursor ? null : endCursor ?? this.endCursor,
    isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    postsErrorMessage: clearPostsError
        ? null
        : postsErrorMessage ?? this.postsErrorMessage,
    paginationErrorMessage: clearPaginationError
        ? null
        : paginationErrorMessage ?? this.paginationErrorMessage,
  );
}

abstract interface class PublicProfileActions {
  Future<void> refresh();
  Future<void> loadMorePosts();
  Future<bool> react(String postId);
  Future<bool> share(String postId);
}

final publicProfileProvider = NotifierProvider.autoDispose
    .family<PublicProfileController, PublicProfileState, String>(
      PublicProfileController.new,
    );

class PublicProfileController extends Notifier<PublicProfileState>
    implements PublicProfileActions {
  PublicProfileController(this.userId);

  static const pageSize = 20;
  final String userId;

  @override
  PublicProfileState build() {
    unawaited(Future<void>.microtask(_initialLoad));
    return const PublicProfileState();
  }

  Future<void> _initialLoad() async {
    try {
      final profile = await ref
          .read(publicProfileRepositoryProvider)
          .fetch(userId);
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: profile,
        isLoadingPosts: true,
      );
      try {
        final page = await ref
            .read(publicProfileSocialRepositoryProvider)
            .feed(authorId: userId, limit: pageSize);
        state = state.copyWith(
          posts: page.posts,
          hasNextPage: page.hasNextPage,
          endCursor: page.endCursor,
          clearEndCursor: page.endCursor == null,
          isLoadingPosts: false,
          clearPostsError: true,
        );
      } catch (error) {
        state = state.copyWith(
          isLoadingPosts: false,
          postsErrorMessage: _message(error),
        );
      }
    } on PublicProfileUnavailableException {
      state = const PublicProfileState(status: PublicProfileStatus.unavailable);
    } catch (error) {
      state = PublicProfileState(
        status: PublicProfileStatus.failure,
        errorMessage: _message(error),
      );
    }
  }

  @override
  Future<void> refresh() async {
    final current = state;
    if (current.profile == null) {
      state = const PublicProfileState();
      await _initialLoad();
      return;
    }

    state = current.copyWith(
      isRefreshing: true,
      clearError: true,
      clearPostsError: true,
      clearPaginationError: true,
    );
    try {
      final profile = await ref
          .read(publicProfileRepositoryProvider)
          .fetch(userId);
      try {
        final page = await ref
            .read(publicProfileSocialRepositoryProvider)
            .feed(authorId: userId, limit: pageSize);
        state = state.copyWith(
          status: PublicProfileStatus.ready,
          profile: profile,
          posts: page.posts,
          hasNextPage: page.hasNextPage,
          endCursor: page.endCursor,
          clearEndCursor: page.endCursor == null,
          isRefreshing: false,
          isLoadingPosts: false,
        );
      } catch (error) {
        state = state.copyWith(
          profile: profile,
          isRefreshing: false,
          postsErrorMessage: _message(error),
        );
      }
    } on PublicProfileUnavailableException {
      state = const PublicProfileState(status: PublicProfileStatus.unavailable);
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _message(error),
      );
    }
  }

  @override
  Future<void> loadMorePosts() async {
    final current = state;
    if (current.status != PublicProfileStatus.ready ||
        current.isLoadingMore ||
        !current.hasNextPage ||
        current.endCursor == null) {
      return;
    }
    state = current.copyWith(isLoadingMore: true, clearPaginationError: true);
    try {
      final page = await ref
          .read(publicProfileSocialRepositoryProvider)
          .feed(authorId: userId, cursor: current.endCursor, limit: pageSize);
      state = state.copyWith(
        posts: _mergePosts(current.posts, page.posts),
        hasNextPage: page.hasNextPage,
        endCursor: page.endCursor,
        clearEndCursor: page.endCursor == null,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        paginationErrorMessage: _message(error),
      );
    }
  }

  @override
  Future<bool> react(String postId) async {
    if (!state.posts.any((post) => post.id == postId)) return false;
    try {
      final updated = await ref
          .read(publicProfileSocialRepositoryProvider)
          .react(postId);
      state = state.copyWith(posts: _replacePost(state.posts, updated));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> share(String postId) async {
    if (!state.posts.any((post) => post.id == postId)) return false;
    try {
      final updated = await ref
          .read(publicProfileSocialRepositoryProvider)
          .share(postId);
      state = state.copyWith(posts: _replacePost(state.posts, updated));
      return true;
    } catch (_) {
      return false;
    }
  }
}

String _message(Object error) => error.toString();

List<SocialPost> _replacePost(List<SocialPost> posts, SocialPost updated) => [
  for (final post in posts)
    if (post.id == updated.id) updated else post,
];

List<SocialPost> _mergePosts(
  List<SocialPost> current,
  List<SocialPost> incoming,
) {
  final byId = {for (final post in current) post.id: post};
  for (final post in incoming) {
    byId[post.id] = post;
  }
  return byId.values.toList(growable: false);
}
