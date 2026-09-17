import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/compose_community_post_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import 'golden_fonts.dart';

const _biology = SocialCategory(
  id: 'biology',
  name: 'Biology',
  slug: 'biology',
  memberCount: 2,
  joined: true,
);
const _general = SocialCategory(
  id: 'general',
  name: 'General Discussion',
  slug: 'general',
  memberCount: 5000,
  joined: true,
);
const _history = SocialCategory(
  id: 'history',
  name: 'History & Heritage',
  slug: 'history',
  memberCount: 12,
  joined: false,
);

class _Feed extends SocialFeedNotifier {
  _Feed(this.categories);

  final List<SocialCategory> categories;

  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: categories,
    posts: const [],
    hasNextPage: false,
  );
}

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  final List<({String title, String content, String categoryId})> created = [];

  @override
  Future<SocialPost> createPost({
    required String title,
    required String content,
    required String categoryId,
    String? mediaUrl,
  }) async {
    created.add((title: title, content: content, categoryId: categoryId));
    return SocialPost(
      id: 'new-post',
      title: title,
      content: content,
      reactionCount: 0,
      commentCount: 0,
      shareCount: 0,
      author: const SocialAuthor(
        id: 'me',
        username: 'me',
        displayName: 'Me',
        avatarUrl: '',
      ),
      category: _general,
      createdAt: DateTime.utc(2026, 9, 17),
      updatedAt: DateTime.utc(2026, 9, 17),
    );
  }
}

Future<_FakeSocialApi> _pump(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  bool dark = false,
  List<SocialCategory> categories = const [_biology, _general, _history],
  String? communityId,
}) async {
  tester.view.physicalSize = size;
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
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (_, _) => const Scaffold(body: Text('before-compose')),
      ),
      GoRoute(
        path: '/compose',
        builder: (_, _) => ComposeCommunityPostScreen(communityId: communityId),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialApiProvider.overrideWithValue(api),
        socialFeedProvider.overrideWith(() => _Feed(categories)),
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
  router.push('/compose');
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  return api;
}

void main() {
  setUpAll(loadRiksaGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets('composer on a phone ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await _pump(tester, dark: dark, communityId: 'general');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/compose_post_phone_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });
  }

  testWidgets('composer keeps a phone-width column on desktop', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1280, 800), dark: true);
    final column = tester.getSize(find.byType(Form));
    expect(column.width, lessThanOrEqualTo(640));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/compose_post_desktop_dark.png'),
    );
  });

  testWidgets('picks a joined community from the sheet and publishes', (
    tester,
  ) async {
    final api = await _pump(tester);
    expect(find.text('Biology'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('compose-community')));
    await tester.pumpAndSettle();
    // Communities the reader has not joined are not offered.
    expect(find.byKey(const ValueKey('compose-community-history')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('compose-community-general')));
    await tester.pumpAndSettle();
    expect(find.text('General Discussion'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('compose-title')),
      'How do I revise faster?',
    );
    await tester.enterText(
      find.byKey(const ValueKey('compose-body')),
      'I have two weeks before the national exam.',
    );
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();

    expect(api.created.single.categoryId, 'general');
    expect(api.created.single.title, 'How do I revise faster?');
    expect(find.text('before-compose'), findsOneWidget);
  });

  testWidgets('without a joined community, posting is off', (tester) async {
    final api = await _pump(tester, categories: const [_history]);
    expect(
      find.byKey(const ValueKey('compose-browse-communities')),
      findsOneWidget,
    );
    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('compose-submit')),
    );
    expect(submit.onPressed, isNull);
    expect(api.created, isEmpty);
  });
}
