import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/network/moderation_error.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/auth/data/external_link_opener.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_post_detail_screen.dart';
import 'package:riksa_app/features/social/presentation/widgets/post_photo.dart';
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

SocialComment _reply(String id) => SocialComment(
  id: id,
  content: 'A reply',
  author: _commentAuthor,
  postId: 'post-1',
  parentId: 'comment-1',
  createdAt: DateTime.utc(2026, 8, 3),
  updatedAt: DateTime.utc(2026, 8, 3),
);

SocialPost _postWith({
  String? title,
  String? content,
  String? mediaUrl,
  int? commentCount,
}) => SocialPost(
  id: _post.id,
  title: title ?? _post.title,
  content: content ?? _post.content,
  mediaUrl: mediaUrl ?? _post.mediaUrl,
  reactionCount: _post.reactionCount,
  commentCount: commentCount ?? _post.commentCount,
  shareCount: _post.shareCount,
  myReaction: _post.myReaction,
  author: _post.author,
  category: _post.category,
  createdAt: _post.createdAt,
  updatedAt: _post.updatedAt,
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
      tester
          .widget<Padding>(find.byKey(const ValueKey('post-detail-body')))
          .padding,
      const EdgeInsets.only(top: 8, bottom: 8),
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('comment-card-comment-1')),
                  )
                  .decoration
              as BoxDecoration)
          .color,
      tester
          .element(find.byKey(const ValueKey('comment-card-comment-1')))
          .riksa
          .surface,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('comment-composer')))
          .decoration
          ?.fillColor,
      isNull,
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
    // The send button enables on the next frame, once it sees the text.
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-comment-button')));
    await tester.pumpAndSettle();

    // Verify parentId was passed correctly
    expect(api.lastCreatedParentId, 'comment-1');

    // The nested reply card is rendered
    expect(
      find.byKey(const ValueKey('comment-card-comment-2')),
      findsOneWidget,
    );
    expect(find.text('Happy to help with math questions!'), findsOneWidget);
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

      final commentButton = find.byKey(
        const ValueKey('post-detail-comment-button'),
      );
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

      final l10n = AppLocalizations.of(tester.element(deleteButton))!;
      expect(find.text(l10n.commentDeleteTitle), findsOneWidget);
      expect(find.text(l10n.commentDeleteMessage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.cancel),
        ),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
      await tester.pumpAndSettle();

      expect(api.lastDeletedCommentId, 'comment-1');
      expect(
        find.byKey(const ValueKey('comment-card-comment-1')),
        findsNothing,
      );
    },
  );

  testWidgets('opens https markdown links and ignores unsafe schemes', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client)
      ..postValue = _postWith(
        content:
            '[HTTPS](https://example.org/notes)\n\n[Unsafe](javascript:alert(1))',
      );
    Uri? opened;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialApiProvider.overrideWithValue(api),
          externalLinkOpenerProvider.overrideWithValue((uri) async {
            opened = uri;
            return true;
          }),
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

    await tester.tap(find.text('HTTPS'));
    await tester.pump();
    expect(opened, Uri.parse('https://example.org/notes'));
    await tester.tap(find.text('Unsafe'));
    await tester.pump();
    expect(opened, Uri.parse('https://example.org/notes'));
  });

  testWidgets('post photos open the viewer and close by button or swipe', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client)
      ..postValue = _postWith(mediaUrl: 'https://example.org/photo.png');

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

    await tester.tap(_detailPhoto());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-viewer-close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('photo-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-viewer-close')), findsNothing);

    await tester.tap(_detailPhoto());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(195, 300), const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-viewer-close')), findsNothing);
  });

  testWidgets('an empty title uses the first body line in the detail header', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client)
      ..postValue = _postWith(title: '', content: 'First line\nSecond line');

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

    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
    expect(
      tester
          .widget<MarkdownBody>(
            find.byKey(const ValueKey('social-post-markdown')),
          )
          .data,
      'Second line',
    );
  });

  testWidgets('single detail photos contain within the height cap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client)
      ..postValue = _postWith(mediaUrl: 'https://example.org/tall-photo.png');

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

    final photo = find.byType(PostPhoto);
    expect(tester.widget<PostPhoto>(photo).fit, BoxFit.contain);
    expect(tester.getSize(photo).height, lessThanOrEqualTo(420));
  });

  testWidgets('Khmer detail text fits at 200 percent text scale', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final api = _FakeSocialApi(client)
      ..postValue = _postWith(
        title: 'ការរៀនដោយការពន្យល់ជំហាននីមួយៗ',
        content:
            'សូមសរសេរចម្លើយពីការចងចាំ រួចពិនិត្យវាម្ដងទៀត។\n\n- ជំហានទីមួយ\n- ជំហានទីពីរ',
      );

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
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SocialPostDetailScreen(postId: 'post-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('social-post-markdown')), findsOneWidget);
  });

  testWidgets('deleting a comment removes its replies from the count', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);
    final replyOne = _reply('reply-1');
    final replyTwo = _reply('reply-2');
    final api = _FakeSocialApi(client)
      ..postValue = _post.copyWith(commentCount: 3)
      ..commentsValue = [_comment, replyOne, replyTwo];

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
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('post-detail-comment-count')),
              matching: find.byType(Text),
            ),
          )
          .data,
      '0',
    );
    expect(find.byKey(const ValueKey('comment-card-reply-1')), findsNothing);
    expect(find.byKey(const ValueKey('comment-card-reply-2')), findsNothing);
  });

  testWidgets('comment likes update optimistically and roll back on failure', (
    tester,
  ) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    final pendingReaction = Completer<SocialPost>();
    fixture.api.commentReactionCompleter = pendingReaction;
    await _pumpDetailScreen(tester, fixture.api);

    final likeButton = find.byKey(
      const ValueKey('comment-like-button-comment-1'),
    );
    final outlineHeart = find.descendant(
      of: likeButton,
      matching: find.byIcon(Icons.favorite_border_rounded),
    );
    final filledHeart = find.descendant(
      of: likeButton,
      matching: find.byIcon(Icons.favorite_rounded),
    );
    expect(outlineHeart, findsOneWidget);
    await tester.ensureVisible(likeButton);
    await tester.tap(likeButton);
    await tester.pump();

    expect(fixture.api.lastReactedCommentId, 'comment-1');
    expect(fixture.api.lastCommentReaction, SocialReaction.love);
    expect(filledHeart, findsOneWidget);
    expect(outlineHeart, findsNothing);

    pendingReaction.completeError(const SocialApiException('reaction failed'));
    await tester.pumpAndSettle();

    expect(outlineHeart, findsOneWidget);
    expect(filledHeart, findsNothing);
  });

  testWidgets('comment actions do not show a Hide control', (tester) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    await _pumpDetailScreen(tester, fixture.api);

    expect(find.text('Hide'), findsNothing);
    expect(find.text('Like'), findsOneWidget);
  });

  testWidgets('does not add synthetic visibility copy beside the count', (
    tester,
  ) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    fixture.api.postValue = _postWith(commentCount: 4);
    await _pumpDetailScreen(tester, fixture.api);

    expect(find.textContaining('Showing'), findsNothing);
    expect(find.textContaining('not visible'), findsNothing);
  });

  testWidgets('renders inline replies and appends the next replies page', (
    tester,
  ) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    final firstReply = _reply('reply-1');
    final nextReply = _reply('reply-2');
    fixture.api
      ..commentThreadsValue = SocialCommentThreadPage(
        threads: [
          SocialCommentThread(
            root: _comment,
            replies: [firstReply],
            repliesHaveNextPage: true,
            repliesEndCursor: 'reply-cursor',
          ),
        ],
        hasNextPage: false,
      )
      ..moreRepliesValue = SocialCommentReplyPage(
        replies: [nextReply],
        hasNextPage: false,
      );
    await _pumpDetailScreen(tester, fixture.api);

    expect(find.byKey(const ValueKey('comment-card-reply-1')), findsOneWidget);
    final viewMore = find.byKey(
      const ValueKey('comment-view-more-replies-comment-1'),
    );
    expect(viewMore, findsOneWidget);
    await tester.ensureVisible(viewMore);
    await tester.pumpAndSettle();
    await tester.tap(viewMore);
    await tester.pumpAndSettle();

    expect(fixture.api.lastCommentRepliesCommentId, 'comment-1');
    expect(fixture.api.lastCommentRepliesCursor, 'reply-cursor');
    expect(fixture.api.lastCommentRepliesLimit, 10);
    expect(find.byKey(const ValueKey('comment-card-reply-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('comment-card-reply-2')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('comment-view-more-replies-comment-1')),
      findsNothing,
    );
  });

  testWidgets('Khmer comment actions have no English labels', (tester) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    fixture.api.commentThreadsValue = SocialCommentThreadPage(
      threads: [
        SocialCommentThread(
          root: _comment,
          replies: const [],
          repliesHaveNextPage: true,
          repliesEndCursor: 'reply-cursor',
        ),
      ],
      hasNextPage: false,
    );
    await _pumpDetailScreen(tester, fixture.api, locale: const Locale('km'));

    final actionRow = find.byKey(
      const ValueKey('comment-action-row-comment-1'),
    );
    final labels = find
        .descendant(of: actionRow, matching: find.byType(Text))
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .toList();
    final l10n = AppLocalizations.of(tester.element(actionRow))!;
    expect(labels, contains(l10n.commentLike));
    expect(labels, contains(l10n.reply));
    expect(labels, isNot(contains('Like')));
    expect(labels, isNot(contains('Unlike')));
    expect(labels, isNot(contains('Reply')));
    expect(labels, isNot(contains('Delete')));
    expect(labels, isNot(contains('Hide')));
    expect(find.text(l10n.commentViewMoreReplies), findsOneWidget);
    expect(find.text('View more replies'), findsNothing);
  });

  testWidgets('a moderation rejection keeps reply target and typed text', (
    tester,
  ) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    fixture.api.createCommentError = const SocialApiException(
      'blocked',
      moderationRejection: ModerationRejection(
        kind: ModerationRejectionKind.blocked,
        reasons: ['PROFANITY'],
      ),
    );
    await _pumpDetailScreen(tester, fixture.api);

    final replyButton = find.byKey(
      const ValueKey('comment-reply-button-comment-1'),
    );
    await tester.ensureVisible(replyButton);
    await tester.tap(replyButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('comment-composer')),
      'This comment needs a rewrite',
    );
    // The send button enables on the next frame, once it sees the text.
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-comment-button')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('comment-composer')),
    );
    final replyIndicator = find.byKey(const ValueKey('reply-indicator-bar'));
    final l10n = AppLocalizations.of(tester.element(replyIndicator))!;
    expect(field.controller!.text, 'This comment needs a rewrite');
    expect(fixture.api.lastCreatedParentId, 'comment-1');
    // The reply target survives: the reply bar still names the author.
    expect(
      find.descendant(
        of: replyIndicator,
        matching: find.textContaining('@Bopha'),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.moderationProfanity), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('send-comment-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('reply keeps a 48 pixel target without a trailing card gap', (
    tester,
  ) async {
    final fixture = _newFakeApi();
    addTearDown(fixture.client.dispose);
    await _pumpDetailScreen(tester, fixture.api);

    final replyButton = find.byKey(
      const ValueKey('comment-reply-button-comment-1'),
    );
    final actionRow = find.byKey(
      const ValueKey('comment-action-row-comment-1'),
    );
    final card = find.byKey(const ValueKey('comment-card-comment-1'));
    final replySize = tester.getSize(replyButton);
    final rowRect = tester.getRect(actionRow);
    final cardRect = tester.getRect(card);

    expect(replySize.width, greaterThanOrEqualTo(48));
    expect(replySize.height, greaterThanOrEqualTo(48));
    expect(rowRect.height, 48);
    expect(cardRect.bottom - rowRect.bottom, lessThanOrEqualTo(1));
  });
}

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  SocialPost postValue = _post;
  List<SocialComment> commentsValue = [_comment];
  SocialCommentThreadPage? commentThreadsValue;
  bool commentReplyHasNextPage = false;
  String? commentReplyEndCursor;
  SocialCommentReplyPage? moreRepliesValue;
  String? lastCreatedParentId;
  String? lastDeletedCommentId;
  String? lastReactedCommentId;
  String? lastCommentRepliesCommentId;
  String? lastCommentRepliesCursor;
  int? lastCommentRepliesLimit;
  SocialReaction? lastCommentReaction;
  SocialApiException? createCommentError;
  Completer<SocialPost>? commentReactionCompleter;

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
  Future<SocialPost> post(String id) async => postValue;

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async => SocialCommentPage(comments: commentsValue, hasNextPage: false);

  @override
  Future<SocialCommentThreadPage> commentThreads({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async {
    final threadPage = commentThreadsValue;
    if (threadPage != null) return threadPage;
    final roots = commentsValue.where((comment) => comment.parentId == null);
    return SocialCommentThreadPage(
      threads: [
        for (final root in roots)
          SocialCommentThread(
            root: root,
            replies: commentsValue
                .where((comment) => comment.parentId == root.id)
                .toList(),
            repliesHaveNextPage: commentReplyHasNextPage,
            repliesEndCursor: commentReplyEndCursor,
          ),
      ],
      hasNextPage: false,
    );
  }

  @override
  Future<SocialCommentReplyPage> commentReplies({
    required String postId,
    required String commentId,
    required String? cursor,
    int limit = 10,
  }) async {
    lastCommentRepliesCommentId = commentId;
    lastCommentRepliesCursor = cursor;
    lastCommentRepliesLimit = limit;
    return moreRepliesValue ??
        const SocialCommentReplyPage(replies: [], hasNextPage: false);
  }

  @override
  Future<SocialComment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    lastCreatedParentId = parentId;
    final error = createCommentError;
    if (error != null) throw error;
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
  Future<SocialPost> reactToComment({
    required String commentId,
    required SocialReaction? reaction,
  }) async {
    lastReactedCommentId = commentId;
    lastCommentReaction = reaction;
    final completer = commentReactionCompleter;
    if (completer != null) return completer.future;
    return _post;
  }

  @override
  Future<void> deleteComment(String id) async {
    lastDeletedCommentId = id;
  }
}

/// The detail photo's key carries the post id, so match on its prefix.
Finder _detailPhoto() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('post-detail-photo'),
);

({DioClient client, _FakeSocialApi api}) _newFakeApi() {
  FlutterSecureStorage.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: 'http://riksa.test/api/v1',
  );
  return (client: client, api: _FakeSocialApi(client));
}

Future<void> _pumpDetailScreen(
  WidgetTester tester,
  _FakeSocialApi api, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [socialApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: locale,
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
}
