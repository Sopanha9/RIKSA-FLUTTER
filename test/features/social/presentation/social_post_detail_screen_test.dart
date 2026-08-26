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
import 'package:riksa_app/features/social/presentation/social_post_detail_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _author = SocialAuthor(
  id: 'user-2',
  username: 'dara',
  displayName: 'Dara',
  avatarUrl: '',
);

const _commentAuthor = SocialAuthor(
  id: 'user-3',
  username: 'bopha',
  displayName: 'Bopha',
  avatarUrl: '',
);

final _post = SocialPost(
  id: 'post-1',
  title: 'A public discussion',
  content: 'A useful note.',
  reactionCount: 3,
  commentCount: 1,
  shareCount: 0,
  author: _author,
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

final _comment = SocialComment(
  id: 'comment-1',
  content: 'Thanks for sharing.',
  author: _commentAuthor,
  postId: 'post-1',
  createdAt: DateTime.utc(2026, 8, 2),
  updatedAt: DateTime.utc(2026, 8, 2),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens profiles from post-detail and comment authors', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client);
    final router = GoRouter(
      initialLocation: '/community/posts/post-1',
      routes: [
        GoRoute(
          path: '/community/posts/:id',
          builder: (_, state) =>
              SocialPostDetailScreen(postId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) =>
              Scaffold(body: Text('profile-${state.pathParameters['userId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialApiProvider.overrideWithValue(api)],
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

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.editorialNeutralCanvas,
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('post-detail-body')),
                  )
                  .decoration
              as BoxDecoration)
          .color,
      AppColors.editorialNeutralSurface,
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('comment-card-comment-1')),
                  )
                  .decoration
              as BoxDecoration)
          .color,
      AppColors.editorialNeutralSurface,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('comment-composer')))
          .decoration
          ?.fillColor,
      AppColors.editorialField,
    );

    await tester.tap(find.byKey(const ValueKey('detail-author-avatar-user-2')));
    await tester.pumpAndSettle();
    expect(find.text('profile-user-2'), findsOneWidget);

    router.go('/community/posts/post-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comment-author-name-user-3')));
    await tester.pumpAndSettle();
    expect(find.text('profile-user-3'), findsOneWidget);
  });
}

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  @override
  Future<SocialPost> post(String id) async => _post;

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async => SocialCommentPage(comments: [_comment], hasNextPage: false);
}
