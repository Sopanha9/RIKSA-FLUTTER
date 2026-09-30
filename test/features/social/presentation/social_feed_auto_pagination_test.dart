import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/providers/current_user_provider.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_feed_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _joinedCategory = SocialCategory(
  id: 'joined-category',
  name: 'Study Skills',
  slug: 'study-skills',
  memberCount: 12,
  joined: true,
);

SocialPost _post(String id, String title) => SocialPost(
  id: id,
  title: title,
  content: 'A post body',
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'author-1',
    username: 'learner',
    displayName: 'Learner',
    avatarUrl: '',
  ),
  category: _joinedCategory,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

SocialFeedPage _page(
  List<SocialPost> posts, {
  required bool hasNextPage,
  required String? endCursor,
}) => SocialFeedPage(
  posts: posts,
  hasNextPage: hasNextPage,
  endCursor: endCursor,
);

class _PaginationSocialApi extends SocialApi {
  _PaginationSocialApi(this.pageFor)
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final SocialFeedPage Function(String? cursor, int callIndex) pageFor;
  final requestedCursors = <String?>[];

  @override
  Future<List<SocialCategory>> categories() async => const [_joinedCategory];

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async {
    requestedCursors.add(cursor);
    return pageFor(cursor, requestedCursors.length - 1);
  }
}

Future<void> _pumpFeed(WidgetTester tester, _PaginationSocialApi api) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        socialApiProvider.overrideWithValue(api),
        communityStreakProvider.overrideWith(
          (ref) async => const CommunityStreak(current: 0, highest: 0),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: const SocialFeedScreen(startInCommunities: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('communities auto-loads through page three to the first match', (
    tester,
  ) async {
    final api = _PaginationSocialApi(
      (cursor, _) => switch (cursor) {
        null => _page(const [], hasNextPage: true, endCursor: 'page-1'),
        'page-1' => _page(const [], hasNextPage: true, endCursor: 'page-2'),
        'page-2' => _page(
          [_post('match', 'Found on page three')],
          hasNextPage: false,
          endCursor: null,
        ),
        _ => throw StateError('Unexpected cursor $cursor'),
      },
    );

    await _pumpFeed(tester, api);

    expect(api.requestedCursors, [null, 'page-1', 'page-2']);
    expect(find.text('Found on page three'), findsOneWidget);
  });

  testWidgets('a short filtered list auto-loads until it fills the viewport', (
    tester,
  ) async {
    final api = _PaginationSocialApi(
      (cursor, _) => switch (cursor) {
        null => _page(
          [_post('first-match', 'First matching post')],
          hasNextPage: true,
          endCursor: 'page-1',
        ),
        'page-1' => _page(
          List.generate(
            7,
            (index) => _post('extra-$index', 'Extra post $index'),
          ),
          hasNextPage: true,
          endCursor: 'page-2',
        ),
        _ => throw StateError('Unexpected cursor $cursor'),
      },
    );

    await _pumpFeed(tester, api);

    expect(api.requestedCursors, [null, 'page-1']);
    expect(find.text('First matching post'), findsOneWidget);
  });

  testWidgets('automatic pagination stops at five pages and offers Load more', (
    tester,
  ) async {
    final api = _PaginationSocialApi((cursor, index) {
      if (cursor == null) {
        return _page(const [], hasNextPage: true, endCursor: 'page-1');
      }
      return _page(const [], hasNextPage: true, endCursor: 'page-${index + 1}');
    });

    await _pumpFeed(tester, api);

    expect(api.requestedCursors, hasLength(6));
    expect(find.text('Load more'), findsOneWidget);
  });

  testWidgets('does not auto-load when the first page has no next page', (
    tester,
  ) async {
    final api = _PaginationSocialApi(
      (_, _) => _page(const [], hasNextPage: false, endCursor: null),
    );

    await _pumpFeed(tester, api);

    expect(api.requestedCursors, [null]);
    expect(find.text('Load more'), findsNothing);
  });
}
