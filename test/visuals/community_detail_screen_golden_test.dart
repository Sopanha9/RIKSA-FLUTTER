import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/community_detail_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import 'golden_fonts.dart';

const _community = SocialCategory(
  id: 'biology',
  name: 'Biology',
  slug: 'biology',
  description:
      'Cells, genetics, ecosystems and everything alive. Ask questions, '
      'share your notes and help each other prepare for the national exam.',
  memberCount: 1240,
  joined: false,
);

final _posts = [
  SocialPost(
    id: 'post-1',
    title: 'Why do plant cells have a cell wall but animal cells do not?',
    content:
        'Our teacher mentioned it quickly in class. Can someone explain it simply?',
    reactionCount: 48,
    commentCount: 12,
    shareCount: 3,
    author: const SocialAuthor(
      id: 'sokha',
      username: 'sokha.learns',
      displayName: 'Sokha Chan',
      avatarUrl: '',
    ),
    category: _community,
    createdAt: DateTime.utc(2026, 9, 15),
    updatedAt: DateTime.utc(2026, 9, 15),
  ),
  SocialPost(
    id: 'post-2',
    title: 'My one-page summary of photosynthesis',
    content: 'Light reactions, the Calvin cycle, and a diagram I drew.',
    reactionCount: 102,
    commentCount: 7,
    shareCount: 9,
    author: const SocialAuthor(
      id: 'bopha',
      username: 'bopha.pich',
      displayName: 'Bopha Pich',
      avatarUrl: '',
    ),
    category: _community,
    createdAt: DateTime.utc(2026, 9, 14),
    updatedAt: DateTime.utc(2026, 9, 14),
  ),
];

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  bool joined = false;
  String? requestedCategoryId;

  @override
  Future<List<SocialCategory>> categories() async => const [_community];

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async {
    requestedCategoryId = categoryId;
    return SocialFeedPage(posts: _posts, hasNextPage: false);
  }

  @override
  Future<SocialCategory> setCategoryJoined(
    String categoryId, {
    required bool joined,
  }) async {
    this.joined = joined;
    return SocialCategory(
      id: _community.id,
      name: _community.name,
      slug: _community.slug,
      description: _community.description,
      memberCount: _community.memberCount + (joined ? 1 : 0),
      joined: joined,
    );
  }
}

Future<_FakeSocialApi> _pump(WidgetTester tester, {bool dark = false}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  FlutterSecureStorage.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: 'http://riksa.test/api/v1',
  );
  addTearDown(client.dispose);
  final api = _FakeSocialApi(client);
  final router = GoRouter(
    initialLocation: '/communities/biology',
    routes: [
      GoRoute(
        path: '/communities/:id',
        // No extra: the screen has to find the community on its own.
        builder: (_, state) =>
            CommunityDetailScreen(communityId: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialApiProvider.overrideWithValue(api),
        currentUserIdProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Asset images decode off the fake clock; wait for them before capturing.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
  return api;
}

void main() {
  setUpAll(loadRiksaGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets('community page ${dark ? 'dark' : 'light'}', (tester) async {
      await _pump(tester, dark: dark);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/community_detail_en_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });
  }

  testWidgets('loads its own feed, joins, and re-sorts', (tester) async {
    final api = await _pump(tester);
    expect(api.requestedCategoryId, 'biology');
    expect(find.text('Biology'), findsOneWidget);

    // Only members can post.
    expect(find.byKey(const ValueKey('community-create-post')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('community-detail-toggle')));
    await tester.pumpAndSettle();
    expect(api.joined, isTrue);
    expect(find.text('Joined'), findsOneWidget);
    expect(find.byKey(const ValueKey('community-create-post')), findsOneWidget);

    double top(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('community-post-$id'))).dy;
    expect(top('post-1'), lessThan(top('post-2')));

    await tester.tap(find.byKey(const ValueKey('community-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('community-sort-top')));
    await tester.pumpAndSettle();
    expect(top('post-2'), lessThan(top('post-1')));
  });
}
