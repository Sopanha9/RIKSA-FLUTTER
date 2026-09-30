import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/providers/current_user_provider.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';

/// The feed is kept for the life of the app, so a post approved by a
/// moderator after the first fetch has to be picked up on the way back in.
void main() {
  late _MockBlogApi api;

  void answerWith(List<BlogPost> posts) {
    when(
      () => api.listPosts(
        categoryId: any(named: 'categoryId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => _page(posts));
  }

  setUp(() {
    api = _MockBlogApi();
    answerWith(const []);
  });

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        blogApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a fresh list is left alone', () async {
    final container = containerWith();
    final notifier = container.read(blogFeedProvider.notifier);
    await notifier.load();
    clearInteractions(api);

    await notifier.refreshIfStale();

    verifyNever(
      () => api.listPosts(
        categoryId: any(named: 'categoryId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    );
  });

  test('a stale list picks up a newly approved post', () async {
    final container = containerWith();
    final notifier = container.read(blogFeedProvider.notifier);
    await notifier.load();
    expect((container.read(blogFeedProvider) as BlogFeedLoaded).posts, isEmpty);

    // The moderator approves it between the two visits.
    answerWith([_approved]);
    await notifier.refreshIfStale(maxAge: Duration.zero);

    final state = container.read(blogFeedProvider) as BlogFeedLoaded;
    expect(state.posts.single.id, 'blog-1');
  });

  test('the active category survives the refresh', () async {
    final container = containerWith();
    final notifier = container.read(blogFeedProvider.notifier);
    await notifier.load(categoryId: 'c1');

    await notifier.refreshIfStale(maxAge: Duration.zero);

    verify(
      () => api.listPosts(
        categoryId: 'c1',
        page: 0,
        size: any(named: 'size'),
      ),
    ).called(2);
  });

  test('a failed feed retries on the way back in', () async {
    final container = containerWith();
    when(
      () => api.listPosts(
        categoryId: any(named: 'categoryId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenThrow(Exception('offline'));
    final notifier = container.read(blogFeedProvider.notifier);
    await notifier.load();
    expect(container.read(blogFeedProvider), isA<BlogFeedError>());

    answerWith([_approved]);
    await notifier.refreshIfStale();

    expect(container.read(blogFeedProvider), isA<BlogFeedLoaded>());
  });

  test('liking a post does not make the list look freshly fetched', () async {
    final container = containerWith();
    answerWith([_approved]);
    final notifier = container.read(blogFeedProvider.notifier);
    await notifier.load();
    final before =
        (container.read(blogFeedProvider) as BlogFeedLoaded).loadedAt;

    when(() => api.toggleLike('blog-1')).thenAnswer((_) async => _approved);
    await notifier.toggleLike('blog-1');

    final after = (container.read(blogFeedProvider) as BlogFeedLoaded).loadedAt;
    expect(after, before);
  });
}

class _MockBlogApi extends Mock implements BlogApi {}

BlogPage _page(List<BlogPost> posts) => BlogPage(
  content: posts,
  page: 0,
  size: 20,
  totalElements: posts.length,
  totalPages: 1,
);

final _approved = BlogPost(
  id: 'blog-1',
  authorId: 'user-2',
  title: 'Approved after the feed loaded',
  content: 'Body.',
  status: BlogStatus.approved,
  viewCount: 0,
  likeCount: 0,
  categoryId: 'c1',
  liked: false,
  createdAt: DateTime.utc(2026, 9, 5),
  updatedAt: DateTime.utc(2026, 9, 5),
);
