import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/providers/current_user_provider.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';

class _ControlledSocialApi extends SocialApi {
  _ControlledSocialApi()
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final requests = <Completer<SocialFeedPage>>[];
  Completer<SocialPost>? createPostRequest;
  Completer<SocialPost>? reactionRequest;

  @override
  Future<List<SocialCategory>> categories() async => const [];

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) {
    final request = Completer<SocialFeedPage>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<SocialPost> createPost({
    required String title,
    required String content,
    required String categoryId,
    String? mediaUrl,
  }) => createPostRequest!.future;

  @override
  Future<SocialPost> react({
    required String postId,
    required SocialReaction reaction,
  }) => reactionRequest!.future;
}

SocialFeedPage _page(
  String cursor, {
  List<SocialPost> posts = const [],
  bool hasNextPage = false,
}) => SocialFeedPage(posts: posts, hasNextPage: hasNextPage, endCursor: cursor);

const _category = SocialCategory(
  id: 'category-1',
  name: 'Study Skills',
  slug: 'study-skills',
  memberCount: 4,
  joined: true,
);

SocialPost _post(String id, {SocialReaction? reaction, int reactions = 0}) =>
    SocialPost(
      id: id,
      title: 'Post $id',
      content: 'Body',
      reactionCount: reactions,
      commentCount: 0,
      shareCount: 0,
      author: const SocialAuthor(
        id: 'author-1',
        username: 'learner',
        displayName: 'Learner',
        avatarUrl: '',
      ),
      category: _category,
      myReaction: reaction,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );

class _SeededSocialFeedNotifier extends SocialFeedNotifier {
  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [_category],
    posts: [_post('original')],
    hasNextPage: true,
    endCursor: 'page-1',
  );
}

void main() {
  test('older social response cannot replace a newer selection', () async {
    final api = _ControlledSocialApi();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        socialApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(socialFeedProvider);
    final newer = container
        .read(socialFeedProvider.notifier)
        .selectCategory('physics');
    expect(api.requests, hasLength(2));
    api.requests[1].complete(_page('new'));
    await newer;
    api.requests[0].complete(_page('old'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(socialFeedProvider) as SocialFeedLoaded;
    expect(state.selectedCategoryId, 'physics');
    expect(state.endCursor, 'new');
  });

  test(
    'a reaction toggled during post creation survives the create response',
    () async {
      final api = _ControlledSocialApi()
        ..createPostRequest = Completer<SocialPost>()
        ..reactionRequest = Completer<SocialPost>();
      final container = ProviderContainer(
        overrides: [
          socialApiProvider.overrideWithValue(api),
          socialFeedProvider.overrideWith(_SeededSocialFeedNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(socialFeedProvider.notifier);

      final creating = notifier.createPost(
        title: 'Created while reacting',
        content: 'Body',
        categoryId: _category.id,
      );
      final reacting = notifier.toggleReaction('original');
      api.reactionRequest!.complete(
        _post('original', reaction: SocialReaction.upvote, reactions: 1),
      );
      expect(await reacting, isTrue);

      api.createPostRequest!.complete(_post('created'));
      expect(await creating, isNull);

      final state = container.read(socialFeedProvider) as SocialFeedLoaded;
      expect(
        state.posts.map((post) => post.id),
        containsAll(['created', 'original']),
      );
      final original = state.posts.singleWhere((post) => post.id == 'original');
      expect(original.myReaction, SocialReaction.upvote);
      expect(original.reactionCount, 1);
    },
  );

  test(
    'loadMore and createPost keep the page and dedupe their shared post',
    () async {
      final api = _ControlledSocialApi()
        ..createPostRequest = Completer<SocialPost>();
      final container = ProviderContainer(
        overrides: [
          socialApiProvider.overrideWithValue(api),
          socialFeedProvider.overrideWith(_SeededSocialFeedNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(socialFeedProvider.notifier);

      final creating = notifier.createPost(
        title: 'Created during pagination',
        content: 'Body',
        categoryId: _category.id,
      );
      final loadingMore = notifier.loadMore();
      api.requests.single.complete(
        _page('page-2', posts: [_post('created'), _post('page-post')]),
      );
      await loadingMore;

      api.createPostRequest!.complete(_post('created'));
      expect(await creating, isNull);

      final posts =
          (container.read(socialFeedProvider) as SocialFeedLoaded).posts;
      expect(posts.map((post) => post.id), [
        'created',
        'original',
        'page-post',
      ]);
      expect(posts.where((post) => post.id == 'created'), hasLength(1));
    },
  );

  test(
    'a failed optimistic reaction rolls back without dropping a new post',
    () async {
      final api = _ControlledSocialApi()
        ..createPostRequest = Completer<SocialPost>()
        ..reactionRequest = Completer<SocialPost>();
      final container = ProviderContainer(
        overrides: [
          socialApiProvider.overrideWithValue(api),
          socialFeedProvider.overrideWith(_SeededSocialFeedNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(socialFeedProvider.notifier);

      final reacting = notifier.toggleReaction('original');
      expect(
        (container.read(socialFeedProvider) as SocialFeedLoaded)
            .posts
            .single
            .myReaction,
        SocialReaction.upvote,
      );
      final creating = notifier.createPost(
        title: 'New post',
        content: 'Body',
        categoryId: _category.id,
      );
      api.createPostRequest!.complete(_post('created'));
      await creating;
      api.reactionRequest!.completeError(Exception('offline'));
      expect(await reacting, isFalse);

      final state = container.read(socialFeedProvider) as SocialFeedLoaded;
      expect(
        state.posts.map((post) => post.id),
        containsAll(['created', 'original']),
      );
      final original = state.posts.singleWhere((post) => post.id == 'original');
      expect(original.myReaction, isNull);
      expect(original.reactionCount, 0);
    },
  );
}
