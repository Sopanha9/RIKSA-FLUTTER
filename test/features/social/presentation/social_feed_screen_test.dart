import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_feed_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _category = SocialCategory(
  id: 'category-1',
  name: 'Study Skills',
  slug: 'study-skills',
  description: 'Learn how to learn.',
  memberCount: 148,
  joined: false,
);

final _post = SocialPost(
  id: 'post-1',
  title: 'The two-minute recall habit',
  content: 'Close your notes and explain the idea in your own words.',
  reactionCount: 18,
  commentCount: 5,
  shareCount: 3,
  author: const SocialAuthor(
    id: 'user-2',
    username: 'dara.learns',
    displayName: 'Dara Chhay',
    avatarUrl: '',
  ),
  category: _category,
  createdAt: DateTime.utc(2026, 8, 22),
  updatedAt: DateTime.utc(2026, 8, 22),
);

final _blogPost = BlogPost(
  id: 'blog-1',
  authorId: 'user-2',
  title: 'How curiosity improves learning',
  content: 'A practical field note from the RIKSA learning community.',
  status: BlogStatus.approved,
  viewCount: 34,
  likeCount: 7,
  categoryId: 'category-1',
  liked: false,
  createdAt: DateTime.utc(2026, 8, 22),
  updatedAt: DateTime.utc(2026, 8, 22),
);

class _FeedNotifier extends SocialFeedNotifier {
  int loadCalls = 0;

  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [_category],
    posts: [_post],
    hasNextPage: false,
  );

  @override
  Future<void> load({String? categoryId}) async {
    loadCalls += 1;
    state = SocialFeedLoaded(
      categories: const [_category],
      posts: [_post],
      hasNextPage: false,
      selectedCategoryId: categoryId,
    );
  }
}

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sok Sophea',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _BlogNotifier extends BlogFeedNotifier {
  @override
  BlogFeedState build() =>
      BlogFeedLoaded(posts: [_blogPost], page: 0, totalPages: 1);
}

class _LocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() => const LocaleState(
    locale: Locale('en'),
    isReady: true,
    hasSelection: true,
  );
}

void main() {
  testWidgets('renders the glass social shell at phone width', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
          ),
          authProvider.overrideWith(_AuthNotifier.new),
          localeProvider.overrideWith(_LocaleNotifier.new),
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
          home: const SocialFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RIKSA'), findsOneWidget);
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(ValueKey('bottom-nav-item-$index')), findsOneWidget);
    }
    final bottomActiveCircle = find.byKey(
      const ValueKey('bottom-nav-active-circle'),
    );
    final homeCircleX = tester.getTopLeft(bottomActiveCircle).dx;
    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final movingCircleX = tester.getTopLeft(bottomActiveCircle).dx;
    expect(movingCircleX, greaterThan(homeCircleX));
    await tester.pumpAndSettle();
    final leaderboardCircleX = tester.getTopLeft(bottomActiveCircle).dx;
    expect(leaderboardCircleX, greaterThan(movingCircleX));
    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(bottomActiveCircle).dx, closeTo(homeCircleX, .1));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SocialFeedScreen)),
    );
    expect(
      (container.read(socialFeedProvider.notifier) as _FeedNotifier).loadCalls,
      1,
    );
    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-2')));
    await tester.pumpAndSettle();
    expect(find.text('RIKSA AI Tutor is coming soon.'), findsOneWidget);
    expect(tester.getTopLeft(bottomActiveCircle).dx, closeTo(homeCircleX, .1));
    expect(
      find.byKey(const ValueKey('community-drawer-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('streak-pill')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-community-button')),
      findsOneWidget,
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.text('My Feed'), findsOneWidget);
    expect(find.text('Blog'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('my-feed-tab'))).height,
      lessThanOrEqualTo(32),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('my-feed-tab'))).width,
      lessThan(135),
    );
    expect(find.text('For you'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('top-learners-spotlight')),
      findsOneWidget,
    );
    expect(find.text('Top Learners This Week'), findsOneWidget);
    expect(find.byKey(const ValueKey('top-learners-view-all')), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsOneWidget);
    expect(find.byKey(const ValueKey('react-post-1')), findsOneWidget);

    final navigationMorph = find.byKey(const ValueKey('bottom-nav-morph'));
    tester.view.physicalSize = const Size(430, 700);
    await tester.pumpAndSettle();
    final expandedNavigationWidth = tester.getSize(navigationMorph).width;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tester.getSize(navigationMorph).width, closeTo(58, .1));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(navigationMorph).width,
      closeTo(expandedNavigationWidth, .1),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tester.getSize(navigationMorph).width, closeTo(58, .1));
    await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(navigationMorph).width,
      closeTo(expandedNavigationWidth, .1),
    );
    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('community-drawer-button')));
    await tester.pumpAndSettle();
    expect(find.text('@sophea'), findsOneWidget);
    expect(find.text('Set up profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drawer-category-category-1')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('community-accordion')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      find.byKey(const ValueKey('drawer-category-category-1')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Drawer))).pop();
    await tester.pumpAndSettle();

    final sectionScroll = find.byKey(const ValueKey('feed-section-scroll'));
    expect(sectionScroll, findsOneWidget);
    expect(
      find.descendant(of: sectionScroll, matching: find.byType(Icon)),
      findsNothing,
    );

    BoxDecoration tabDecoration(Finder tab) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: tab, matching: find.byType(AnimatedContainer)),
      );
      return container.decoration! as BoxDecoration;
    }

    final feedTab = find.byKey(const ValueKey('my-feed-tab'));
    final blogTab = find.byKey(const ValueKey('blog-tab'));
    expect(
      (tabDecoration(feedTab).border! as Border).top.color,
      AppColors.brandPrimaryHover,
    );
    await tester.tap(find.byKey(const ValueKey('blog-tab')));
    await tester.pumpAndSettle();
    expect(
      (tabDecoration(blogTab).border! as Border).top.color,
      AppColors.brandPrimaryHover,
    );
    expect(
      (tabDecoration(feedTab).border! as Border).top.color,
      isNot(AppColors.brandPrimaryHover),
    );
    expect(find.text('How curiosity improves learning'), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('create-community-button')));
    await tester.pumpAndSettle();
    expect(find.text('Create in Community'), findsOneWidget);
    expect(find.text('Create a post'), findsOneWidget);
    expect(find.text('Ask the community'), findsOneWidget);
  });
}
