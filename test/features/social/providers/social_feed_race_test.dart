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
}

SocialFeedPage _page(String cursor) =>
    SocialFeedPage(posts: const [], hasNextPage: false, endCursor: cursor);

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
}
