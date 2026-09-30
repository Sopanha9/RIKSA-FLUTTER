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
import 'package:riksa_app/features/social/presentation/manage_community_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _author = SocialAuthor(
  id: 'dara',
  username: 'dara',
  displayName: 'Dara',
  avatarUrl: '',
);

SocialCategory _community({
  CommunityRole? role = CommunityRole.owner,
  CommunityPostPermission permission = CommunityPostPermission.members,
  List<CommunityRule> rules = const [CommunityRule(title: 'Be kind')],
  String? pinnedPostId,
}) => SocialCategory(
  id: 'chem',
  name: 'Chem Club',
  slug: 'chem-club',
  memberCount: 3,
  joined: role != null,
  myRole: role,
  postPermission: permission,
  rules: rules,
  pinnedPostId: pinnedPostId,
);

final _post = SocialPost(
  id: 'p1',
  title: 'Balancing equations',
  content: 'A trick that works',
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: _author,
  category: _community(),
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

class _FakeApi extends SocialApi {
  _FakeApi(super.client, this.current);

  SocialCategory current;
  List<CommunityRule>? savedRules;
  CommunityPostPermission? savedPermission;
  String? savedBannerColor;
  final removed = <(String, bool)>[];
  String? pinned = 'unset';

  @override
  Future<SocialCategory?> community(String id) async => current;

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async => SocialFeedPage(posts: [_post], hasNextPage: false);

  @override
  Future<SocialCategory> updateCommunity({
    required String id,
    String? name,
    String? description,
    CommunityPostPermission? postPermission,
    List<CommunityRule>? rules,
    String? iconUrl,
    bool clearIcon = false,
    String? bannerUrl,
    bool clearBanner = false,
    String? bannerColor,
  }) async {
    savedBannerColor = bannerColor ?? savedBannerColor;
    savedRules = rules ?? savedRules;
    savedPermission = postPermission ?? savedPermission;
    return current = _community(
      permission: postPermission ?? current.postPermission,
      rules: rules ?? current.rules,
    );
  }

  @override
  Future<List<CommunityMember>> communityMembers(
    String categoryId, {
    String? query,
  }) async => const [
    CommunityMember(
      user: SocialAuthor(
        id: 'me',
        username: 'me',
        displayName: 'Me',
        avatarUrl: '',
      ),
      role: CommunityRole.owner,
    ),
    CommunityMember(user: _author, role: CommunityRole.member),
  ];

  @override
  Future<List<CommunityBanEntry>> communityBans(String categoryId) async =>
      const [];

  @override
  Future<void> removeCommunityMember(
    String categoryId,
    String userId, {
    bool ban = false,
    String? reason,
  }) async => removed.add((userId, ban));

  @override
  Future<SocialCategory> pinCommunityPost(
    String categoryId,
    String? postId,
  ) async {
    pinned = postId;
    return current = _community(pinnedPostId: postId);
  }
}

Future<_FakeApi> _pump(
  WidgetTester tester,
  SocialCategory community, {
  String initial = '/communities/chem',
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  FlutterSecureStorage.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: 'http://riksa.test/api/v1',
  );
  addTearDown(client.dispose);
  final api = _FakeApi(client, community);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/communities/:id',
        builder: (_, state) =>
            CommunityDetailScreen(communityId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'manage',
            builder: (_, state) =>
                ManageCommunityScreen(communityId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialApiProvider.overrideWithValue(api),
        currentUserIdProvider.overrideWithValue('me'),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
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
  return api;
}

void main() {
  testWidgets('members see the rules but no manage button', (tester) async {
    await _pump(tester, _community(role: CommunityRole.member));

    expect(find.text('Community rules'), findsOneWidget);
    expect(find.byKey(const ValueKey('community-manage')), findsNothing);
    expect(find.byKey(const ValueKey('post-options-p1')), findsNothing);
    expect(find.byKey(const ValueKey('community-create-post')), findsOneWidget);
  });

  testWidgets('members cannot post when only moderators may', (tester) async {
    await _pump(
      tester,
      _community(
        role: CommunityRole.member,
        permission: CommunityPostPermission.moderators,
      ),
    );

    expect(find.byKey(const ValueKey('community-create-post')), findsNothing);
    expect(find.text('Only moderators can post here.'), findsOneWidget);
  });

  testWidgets('a moderator can pin and ban from the post menu', (tester) async {
    final api = await _pump(tester, _community(role: CommunityRole.moderator));

    expect(find.text('Moderator'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('post-options-p1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .state<PopupMenuButtonState<Object?>>(
          find.byKey(const ValueKey('post-options-p1')),
        )
        .showButtonMenu();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin to top'));
    await tester.pumpAndSettle();
    expect(api.pinned, 'p1');
    expect(
      find.byKey(const ValueKey('community-pinned-label')),
      findsOneWidget,
    );

    tester
        .state<PopupMenuButtonState<Object?>>(
          find.byKey(const ValueKey('post-options-p1')),
        )
        .showButtonMenu();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ban from community'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('community-confirm')));
    await tester.pumpAndSettle();
    expect(api.removed, [('dara', true)]);
  });

  testWidgets('the owner edits rules and posting settings', (tester) async {
    final api = await _pump(
      tester,
      _community(),
      initial: '/communities/chem/manage',
    );

    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('banner-color-#FF5C8A')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('manage-permission-moderators')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manage-permission-moderators')),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('manage-save-settings')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manage-save-settings')));
    await tester.pumpAndSettle();
    expect(api.savedPermission, CommunityPostPermission.moderators);
    expect(api.savedBannerColor, '#FF5C8A');
    // Let the "Saved" snackbar clear the bottom buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manage-add-rule')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('rule-title')), 'No spam');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manage-save-rules')));
    await tester.pumpAndSettle();
    expect(api.savedRules?.map((rule) => rule.title), ['Be kind', 'No spam']);
  });

  testWidgets('a moderator only gets the member tools', (tester) async {
    final api = await _pump(
      tester,
      _community(role: CommunityRole.moderator),
      initial: '/communities/chem/manage',
    );

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Members'), findsOneWidget);
    // Nobody can act on the owner; the member row has a menu.
    expect(find.byKey(const ValueKey('manage-member-menu-me')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('manage-member-menu-dara')));
    await tester.pumpAndSettle();
    expect(find.text('Make moderator'), findsNothing);
    await tester.tap(find.text('Remove from community'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-removal')));
    await tester.pumpAndSettle();
    expect(api.removed, [('dara', false)]);
  });
}
