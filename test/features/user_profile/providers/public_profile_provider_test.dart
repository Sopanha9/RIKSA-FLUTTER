import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';

const _profile = PublicProfile(
  id: 'user-2',
  username: 'dara',
  displayName: 'Dara',
  isVerified: true,
  totalXp: 2400,
  currentTier: 'SCHOLAR',
  achievements: [],
);

const _refreshedProfile = PublicProfile(
  id: 'user-2',
  username: 'dara',
  displayName: 'Dara refreshed',
  isVerified: true,
  totalXp: 2600,
  currentTier: 'SCHOLAR',
  achievements: [],
);

final _post = SocialPost(
  id: 'post-1',
  title: 'Public post',
  content: 'A useful note.',
  reactionCount: 3,
  commentCount: 1,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'user-2',
    username: 'dara',
    displayName: 'Dara',
    avatarUrl: '',
  ),
  category: const SocialCategory(
    id: 'math',
    name: 'Mathematics',
    slug: 'mathematics',
    memberCount: 10,
    joined: true,
  ),
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

final _secondPost = SocialPost(
  id: 'post-2',
  title: 'Another public post',
  content: 'A second note.',
  reactionCount: 1,
  commentCount: 7,
  shareCount: 0,
  author: _post.author,
  category: _post.category,
  createdAt: DateTime.utc(2026, 8, 2),
  updatedAt: DateTime.utc(2026, 8, 2),
);

void main() {
  test('loads public identity and the first author feed page', () async {
    final profiles = _FakeProfiles();
    final social = _FakePublicProfileSocial();
    final container = ProviderContainer(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(profiles),
        publicProfileSocialRepositoryProvider.overrideWithValue(social),
      ],
    );
    addTearDown(container.dispose);
    container.listen(publicProfileProvider('user-2'), (_, _) {});

    expect(
      container.read(publicProfileProvider('user-2')).status,
      PublicProfileStatus.loading,
    );

    await _flushAsync();

    final state = container.read(publicProfileProvider('user-2'));
    expect(state.status, PublicProfileStatus.ready);
    expect(state.profile, _profile);
    expect(state.posts.single.id, 'post-1');
    expect(state.hasNextPage, isTrue);
    expect(state.endCursor, 'post-1');
    expect(profiles.requestedUserIds, ['user-2']);
    expect(social.feedRequests.single.authorId, 'user-2');
  });

  test('keeps a loaded profile when its posts fail independently', () async {
    final social = _FakePublicProfileSocial()..feedError = Exception('offline');
    final container = _container(social: social);
    addTearDown(container.dispose);
    container.listen(publicProfileProvider('user-2'), (_, _) {});

    await _flushAsync();

    final state = container.read(publicProfileProvider('user-2'));
    expect(state.status, PublicProfileStatus.ready);
    expect(state.profile, _profile);
    expect(state.posts, isEmpty);
    expect(state.postsErrorMessage, contains('offline'));
  });

  test('maps inaccessible people to the unavailable state', () async {
    final profiles = _FakeProfiles()
      ..error = const PublicProfileUnavailableException();
    final container = _container(profiles: profiles);
    addTearDown(container.dispose);
    container.listen(publicProfileProvider('missing-user'), (_, _) {});

    await _flushAsync();

    expect(
      container.read(publicProfileProvider('missing-user')).status,
      PublicProfileStatus.unavailable,
    );
  });

  test(
    'refresh preserves content while replacing profile and first page',
    () async {
      final profiles = _FakeProfiles();
      final social = _FakePublicProfileSocial();
      final container = _container(profiles: profiles, social: social);
      addTearDown(container.dispose);
      container.listen(publicProfileProvider('user-2'), (_, _) {});
      await _flushAsync();

      final refreshCompleter = Completer<PublicProfile>();
      profiles.nextFetch = refreshCompleter.future;
      final operation = container
          .read(publicProfileProvider('user-2').notifier)
          .refresh();
      await Future<void>.delayed(Duration.zero);

      final refreshing = container.read(publicProfileProvider('user-2'));
      expect(refreshing.isRefreshing, isTrue);
      expect(refreshing.profile, _profile);
      expect(refreshing.posts.single.id, 'post-1');

      refreshCompleter.complete(_refreshedProfile);
      await operation;

      final refreshed = container.read(publicProfileProvider('user-2'));
      expect(refreshed.isRefreshing, isFalse);
      expect(refreshed.profile, _refreshedProfile);
      expect(profiles.requestedUserIds, ['user-2', 'user-2']);
    },
  );

  test('paginates posts and retains content when a later page fails', () async {
    final social = _FakePublicProfileSocial()
      ..pageByCursor['post-1'] = SocialFeedPage(
        posts: [_secondPost],
        hasNextPage: true,
        endCursor: 'post-2',
      );
    final container = _container(social: social);
    addTearDown(container.dispose);
    container.listen(publicProfileProvider('user-2'), (_, _) {});
    await _flushAsync();

    final controller = container.read(publicProfileProvider('user-2').notifier);
    await controller.loadMorePosts();

    var state = container.read(publicProfileProvider('user-2'));
    expect(state.posts, hasLength(2));
    expect(state.endCursor, 'post-2');

    social.feedError = Exception('next page failed');
    await controller.loadMorePosts();

    state = container.read(publicProfileProvider('user-2'));
    expect(state.posts, hasLength(2));
    expect(state.isLoadingMore, isFalse);
    expect(state.paginationErrorMessage, contains('next page failed'));
  });

  test(
    'reaction and share replace the affected post from server results',
    () async {
      final social = _FakePublicProfileSocial()
        ..reactionResult = _post.copyWith(
          reactionCount: 4,
          myReaction: SocialReaction.upvote,
        )
        ..shareResult = _post.copyWith(shareCount: 1);
      final container = _container(social: social);
      addTearDown(container.dispose);
      container.listen(publicProfileProvider('user-2'), (_, _) {});
      await _flushAsync();
      final controller = container.read(
        publicProfileProvider('user-2').notifier,
      );

      expect(await controller.react('post-1'), isTrue);
      expect(
        container
            .read(publicProfileProvider('user-2'))
            .posts
            .single
            .reactionCount,
        4,
      );
      expect(await controller.share('post-1'), isTrue);
      expect(
        container.read(publicProfileProvider('user-2')).posts.single.shareCount,
        1,
      );
      expect(social.reactedPostIds, ['post-1']);
      expect(social.sharedPostIds, ['post-1']);
    },
  );
}

ProviderContainer _container({
  _FakeProfiles? profiles,
  _FakePublicProfileSocial? social,
}) => ProviderContainer(
  overrides: [
    publicProfileRepositoryProvider.overrideWithValue(
      profiles ?? _FakeProfiles(),
    ),
    publicProfileSocialRepositoryProvider.overrideWithValue(
      social ?? _FakePublicProfileSocial(),
    ),
  ],
);

Future<void> _flushAsync() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeProfiles implements PublicProfileRepository {
  final List<String> requestedUserIds = [];
  Object? error;
  Future<PublicProfile>? nextFetch;

  @override
  Future<PublicProfile> fetch(String userId) async {
    requestedUserIds.add(userId);
    final failure = error;
    if (failure != null) throw failure;
    final next = nextFetch;
    if (next != null) {
      nextFetch = null;
      return next;
    }
    return _profile;
  }
}

class _FeedRequest {
  const _FeedRequest(this.authorId, this.cursor);

  final String authorId;
  final String? cursor;
}

class _FakePublicProfileSocial implements PublicProfileSocialRepository {
  final List<_FeedRequest> feedRequests = [];
  final Map<String, SocialFeedPage> pageByCursor = {};
  final List<String> reactedPostIds = [];
  final List<String> sharedPostIds = [];
  Object? feedError;
  SocialPost? reactionResult;
  SocialPost? shareResult;

  @override
  Future<SocialFeedPage> feed({
    required String authorId,
    String? cursor,
    required int limit,
  }) async {
    feedRequests.add(_FeedRequest(authorId, cursor));
    final failure = feedError;
    if (failure != null) throw failure;
    final cursorPage = pageByCursor[cursor];
    if (cursorPage != null) return cursorPage;
    return SocialFeedPage(
      posts: [_post],
      hasNextPage: true,
      endCursor: 'post-1',
    );
  }

  @override
  Future<SocialPost> react(String postId) async {
    reactedPostIds.add(postId);
    return reactionResult ?? _post;
  }

  @override
  Future<SocialPost> share(String postId) async {
    sharedPostIds.add(postId);
    return shareResult ?? _post;
  }
}
