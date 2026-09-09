import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
  title: 'គន្លឹះដោះស្រាយសមីការ',
  content: r'សួស្តីអ្នកទាំងអស់គ្នា!\n\n- **ជំហានទី១**: រកសមីការ',
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
    expect(
      tester.widget<Text>(find.text(_post.title)).style?.fontFamily,
      RiksaTypography.khmerBodyFamily,
    );
    final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(markdown.data, isNot(contains(r'\n')));
    expect(markdown.styleSheet?.p?.fontFamily, RiksaTypography.khmerBodyFamily);

    await tester.tap(find.byKey(const ValueKey('detail-author-avatar-user-2')));
    await tester.pumpAndSettle();
    expect(find.text('profile-user-2'), findsOneWidget);

    router.go('/community/posts/post-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comment-author-name-user-3')));
    await tester.pumpAndSettle();
    expect(find.text('profile-user-3'), findsOneWidget);
  });

  testWidgets('supports replying to comments and renders nested replies', (
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

    // The reply button is visible on the root comment
    final replyButtonFinder = find.byKey(
      const ValueKey('comment-reply-button-comment-1'),
    );
    expect(replyButtonFinder, findsOneWidget);
    await tester.ensureVisible(replyButtonFinder);
    await tester.pumpAndSettle();

    // Tapping reply shows the reply indicator banner
    await tester.tap(replyButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reply-indicator-bar')), findsOneWidget);
    expect(find.textContaining('Replying to @Bopha'), findsOneWidget);

    // Tapping cancel dismisses the banner
    await tester.tap(find.byKey(const ValueKey('cancel-reply-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reply-indicator-bar')), findsNothing);

    // Tap reply again and send a reply comment
    await tester.ensureVisible(replyButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(replyButtonFinder);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('comment-composer')),
      'Happy to help with math questions!',
    );
    await tester.tap(find.byKey(const ValueKey('send-comment-button')));
    await tester.pumpAndSettle();

    // Verify parentId was passed correctly
    expect(api.lastCreatedParentId, 'comment-1');

    // The nested reply card is rendered
    expect(
      find.byKey(const ValueKey('comment-card-comment-2')),
      findsOneWidget,
    );
    expect(
      find.text('Happy to help with math questions!'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping comment button in post body focuses the comment composer',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
      );
      addTearDown(client.dispose);
      final api = _FakeSocialApi(client);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [socialApiProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('km')],
            home: const SocialPostDetailScreen(postId: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final commentButton = find.byKey(const ValueKey('post-detail-comment-button'));
      expect(commentButton, findsOneWidget);

      await tester.tap(commentButton);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('comment-composer')),
      );
      expect(textField.focusNode?.hasFocus, isTrue);
    },
  );

  testWidgets(
    'allows comment author to delete their own comment after confirmation',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
      );
      addTearDown(client.dispose);
      final api = _FakeSocialApi(client);

      // Current user is user-3 (the comment author)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socialApiProvider.overrideWithValue(api),
            currentUserIdProvider.overrideWithValue('user-3'),
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
            home: const SocialPostDetailScreen(postId: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(
        const ValueKey('comment-delete-button-comment-1'),
      );
      expect(deleteButton, findsOneWidget);
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete comment?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(api.lastDeletedCommentId, 'comment-1');
      expect(
        find.byKey(const ValueKey('comment-card-comment-1')),
        findsNothing,
      );
    },
  );
}

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  String? lastCreatedParentId;
  String? lastDeletedCommentId;

  @override
  Future<List<SocialCategory>> categories() async => [_post.category];

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async => SocialFeedPage(posts: [_post], hasNextPage: false);

  @override
  Future<SocialPost> post(String id) async => _post;

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async => SocialCommentPage(comments: [_comment], hasNextPage: false);

  @override
  Future<SocialComment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    lastCreatedParentId = parentId;
    return SocialComment(
      id: 'comment-2',
      content: content,
      author: _author,
      postId: postId,
      parentId: parentId,
      createdAt: DateTime.utc(2026, 8, 3),
      updatedAt: DateTime.utc(2026, 8, 3),
    );
  }

  @override
  Future<void> deleteComment(String id) async {
    lastDeletedCommentId = id;
  }
}

