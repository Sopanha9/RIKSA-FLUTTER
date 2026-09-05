import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';

/// The author-owned half of the post lifecycle: `updatePost` and `deletePost`
/// are owner-only mutations, so the client has to send the right shape and
/// keep the cached feed honest afterwards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SocialApi apiWith(_GraphqlAdapter adapter) {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);
    return SocialApi(client);
  }

  test('updatePost sends the post id with the rewritten fields', () async {
    final adapter = _GraphqlAdapter({
      'updatePost': _postJson(title: 'Edited title'),
    });

    final updated = await apiWith(adapter).updatePost(
      id: 'post-1',
      title: 'Edited title',
      content: 'Rewritten body',
    );

    expect(adapter.query, contains('mutation UpdatePost'));
    expect(adapter.query, contains(r'updatePost(input: $input)'));
    expect(adapter.variables?['input'], {
      'id': 'post-1',
      'title': 'Edited title',
      'content': 'Rewritten body',
    });
    expect(updated.title, 'Edited title');
  });

  test('deletePost sends the id and accepts a true result', () async {
    final adapter = _GraphqlAdapter({'deletePost': true});

    await apiWith(adapter).deletePost('post-1');

    expect(adapter.query, contains('mutation DeletePost'));
    expect(adapter.variables, {'id': 'post-1'});
  });

  test('deletePost surfaces a refused delete', () async {
    final adapter = _GraphqlAdapter({'deletePost': false});

    expect(
      () => apiWith(adapter).deletePost('post-1'),
      throwsA(isA<SocialApiException>()),
    );
  });

  test('a deleted post leaves the cached feed', () async {
    final container = ProviderContainer(
      overrides: [
        socialApiProvider.overrideWithValue(_StubApi()),
        socialFeedProvider.overrideWith(_StubFeed.new),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(socialFeedProvider.notifier);

    expect(await notifier.deletePost('post-1'), isNull);
    final state = container.read(socialFeedProvider) as SocialFeedLoaded;
    expect(state.posts.map((post) => post.id), ['post-2']);
  });

  test('a refused delete keeps the post and returns the reason', () async {
    final container = ProviderContainer(
      overrides: [
        socialApiProvider.overrideWithValue(
          _StubApi(failure: 'You can only delete your own posts'),
        ),
        socialFeedProvider.overrideWith(_StubFeed.new),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(socialFeedProvider.notifier);

    expect(
      await notifier.deletePost('post-1'),
      'You can only delete your own posts',
    );
    final state = container.read(socialFeedProvider) as SocialFeedLoaded;
    expect(state.posts, hasLength(2));
  });
}

Map<String, dynamic> _postJson({String title = 'Title'}) => {
  'id': 'post-1',
  'title': title,
  'content': 'Rewritten body',
  'mediaUrl': null,
  'reactionCount': 3,
  'commentCount': 1,
  'shareCount': 0,
  'myReaction': null,
  'createdAt': '2026-08-24T10:00:00Z',
  'updatedAt': '2026-09-05T10:00:00Z',
  'author': {
    'id': 'me',
    'username': 'sopanha',
    'displayName': 'Sopanha',
    'avatarUrl': '',
  },
  'category': {
    'id': 'category-1',
    'name': 'Science',
    'slug': 'science',
    'description': null,
    'iconUrl': null,
    'memberCount': 12,
    'joined': true,
  },
};

SocialPost _post(String id) => SocialPost(
  id: id,
  title: 'Post $id',
  content: 'Body',
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'me',
    username: 'sopanha',
    displayName: 'Sopanha',
    avatarUrl: '',
  ),
  category: const SocialCategory(
    id: 'category-1',
    name: 'Science',
    slug: 'science',
    memberCount: 12,
    joined: true,
  ),
  createdAt: DateTime.utc(2026, 8, 24),
  updatedAt: DateTime.utc(2026, 8, 24),
);

class _StubFeed extends SocialFeedNotifier {
  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [],
    posts: [_post('post-1'), _post('post-2')],
    hasNextPage: false,
  );
}

class _StubApi implements SocialApi {
  _StubApi({this.failure});

  final String? failure;

  @override
  Future<void> deletePost(String id) async {
    if (failure != null) throw SocialApiException(failure!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _GraphqlAdapter implements HttpClientAdapter {
  _GraphqlAdapter(this.data);

  final Map<String, dynamic> data;
  String? query;
  Map<String, dynamic>? variables;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = (options.data as Map).cast<String, dynamic>();
    query = (body['query'] as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    variables = (body['variables'] as Map?)?.cast<String, dynamic>();
    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
