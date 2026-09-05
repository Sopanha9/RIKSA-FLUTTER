import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/presentation/blog_feed_screen.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// Only the author gets the edit and delete affordances, and deleting is
/// confirmed before anything leaves the device.
void main() {
  final mine = _post(id: 'mine', authorId: 'me', title: 'My own post');
  final theirs = _post(id: 'theirs', authorId: 'someone', title: 'Their post');

  testWidgets('the owner menu appears only on the signed-in author\'s post', (
    tester,
  ) async {
    await _pumpFeed(tester, posts: [mine, theirs], api: _MockBlogApi());

    expect(find.byTooltip('Post options'), findsOneWidget);
    final menu = tester.getTopLeft(find.byTooltip('Post options'));
    final ownRow = tester.getRect(find.text('My own post'));
    expect(menu.dy, lessThan(ownRow.bottom));
  });

  testWidgets('signed-out readers get no owner menu', (tester) async {
    await _pumpFeed(
      tester,
      posts: [mine, theirs],
      api: _MockBlogApi(),
      userId: null,
    );

    expect(find.byTooltip('Post options'), findsNothing);
  });

  testWidgets('delete asks first, then removes the post', (tester) async {
    final api = _MockBlogApi();
    when(() => api.deletePost(any())).thenAnswer((_) async {});
    await _pumpFeed(tester, posts: [mine, theirs], api: api);

    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();

    // Nothing is deleted until the dialog is confirmed.
    verifyNever(() => api.deletePost(any()));
    await tester.tap(find.text('Keep post'));
    await tester.pumpAndSettle();
    verifyNever(() => api.deletePost(any()));
    expect(find.text('My own post'), findsOneWidget);

    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => api.deletePost('mine')).called(1);
    expect(find.text('My own post'), findsNothing);
    expect(find.text('Their post'), findsOneWidget);
  });
}

BlogPost _post({
  required String id,
  required String authorId,
  required String title,
}) => BlogPost(
  id: id,
  authorId: authorId,
  title: title,
  content: 'A short field note from the Riksa community.',
  status: BlogStatus.approved,
  viewCount: 12,
  likeCount: 3,
  categoryId: 'category-1',
  liked: false,
  createdAt: DateTime.utc(2026, 8, 24),
  updatedAt: DateTime.utc(2026, 8, 24),
);

Future<void> _pumpFeed(
  WidgetTester tester, {
  required List<BlogPost> posts,
  required BlogApi api,
  String? userId = 'me',
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blogFeedProvider.overrideWith(() => _FeedNotifier(posts)),
        blogApiProvider.overrideWithValue(api),
        blogCategoriesProvider.overrideWith((ref) async => const []),
        publicProfileRepositoryProvider.overrideWithValue(_Profiles()),
        currentUserIdProvider.overrideWithValue(userId),
        if (userId != null) authProvider.overrideWith(_AuthStub.new),
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
        home: const BlogFeedScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockBlogApi extends Mock implements BlogApi {}

class _FeedNotifier extends BlogFeedNotifier {
  _FeedNotifier(this.posts);

  final List<BlogPost> posts;

  @override
  BlogFeedState build() => BlogFeedLoaded(posts: posts, page: 0, totalPages: 1);
}

class _AuthStub extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'me',
      username: 'sopanha',
      displayName: 'Sopanha',
      emailVerified: true,
      phoneVerified: true,
      role: 'USER',
    ),
  );
}

class _Profiles implements PublicProfileRepository {
  @override
  Future<PublicProfile> fetch(String userId) async => PublicProfile(
    id: userId,
    username: userId,
    displayName: userId == 'me' ? 'Sopanha' : 'Dara',
    isVerified: false,
    totalXp: 0,
    currentTier: 'STARTER',
    achievements: const [],
  );
}
