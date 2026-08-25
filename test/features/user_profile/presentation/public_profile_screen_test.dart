import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/presentation/public_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

final _post = SocialPost(
  id: 'post-public',
  title: 'How I study algebra',
  content: 'Practice a little each day.',
  reactionCount: 5,
  commentCount: 2,
  shareCount: 1,
  author: const SocialAuthor(
    id: 'user-2',
    username: 'dara',
    displayName: 'Dara',
    avatarUrl: '',
  ),
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

const _profile = PublicProfile(
  id: 'user-2',
  username: 'dara',
  displayName: 'Dara',
  avatarUrl: null,
  bio: 'Learning in public.',
  isVerified: true,
  totalXp: 2400,
  currentTier: 'SCHOLAR',
  achievements: [
    PublicProfileAchievement(
      id: 'achievement-1',
      name: 'Study Starter',
      description: 'Completed a first lesson.',
      rarity: 'RARE',
      unlockedAt: null,
    ),
  ],
  rank: PublicProfileRank(countryRank: 42, provinceRank: 5),
);

void main() {
  testWidgets('renders populated public-safe profile tabs', (tester) async {
    await _pump(
      tester,
      profiles: _Profiles(result: Future.value(_profile)),
      social: _Social(page: _page([_post])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('public-profile-back')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('public-profile-default-cover')),
      findsOneWidget,
    );
    expect(find.text('Dara'), findsWidgets);
    expect(find.text('@dara'), findsOneWidget);
    expect(find.text('Learning in public.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('public-verification-badge')),
      findsOneWidget,
    );
    expect(find.text('2.4K XP'), findsOneWidget);
    expect(find.text('How I study algebra'), findsOneWidget);
    expect(find.textContaining('private@example.test'), findsNothing);
    expect(find.textContaining('+855'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-achievements-tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Study Starter'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-rank-tab')));
    await tester.pumpAndSettle();
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('shows loading and empty post states', (tester) async {
    final pending = Completer<PublicProfile>();
    await _pump(tester, profiles: _Profiles(result: pending.future));
    expect(
      find.byKey(const ValueKey('public-profile-loading')),
      findsOneWidget,
    );

    pending.complete(_profile);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('public-profile-posts-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows retryable error and friendly unavailable states', (
    tester,
  ) async {
    await _pump(
      tester,
      profiles: _Profiles(error: Exception('network failed')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('public-profile-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('public-profile-retry')), findsOneWidget);

    await _pump(
      tester,
      profiles: _Profiles(error: const PublicProfileUnavailableException()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('public-profile-unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('localizes the public profile in Khmer and supports dark theme', (
    tester,
  ) async {
    await _pump(
      tester,
      profiles: _Profiles(result: Future.value(_profile)),
      theme: AppTheme.dark,
      locale: const Locale('km'),
    );
    await tester.pumpAndSettle();

    expect(find.text('សមិទ្ធផល'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SocialFeedPage _page(List<SocialPost> posts) =>
    SocialFeedPage(posts: posts, hasNextPage: false);

Future<void> _pump(
  WidgetTester tester, {
  required _Profiles profiles,
  _Social? social,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(profiles),
        publicProfileSocialRepositoryProvider.overrideWithValue(
          social ?? _Social(page: _page(const [])),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: const PublicProfileScreen(userId: 'user-2'),
      ),
    ),
  );
}

class _Profiles implements PublicProfileRepository {
  _Profiles({this.result, this.error});

  final Future<PublicProfile>? result;
  final Object? error;

  @override
  Future<PublicProfile> fetch(String userId) {
    final failure = error;
    if (failure != null) throw failure;
    return result!;
  }
}

class _Social implements PublicProfileSocialRepository {
  _Social({required this.page});

  final SocialFeedPage page;

  @override
  Future<SocialFeedPage> feed({
    required String authorId,
    String? cursor,
    required int limit,
  }) async => page;

  @override
  Future<SocialPost> react(String postId) async => _post;

  @override
  Future<SocialPost> share(String postId) async => _post;
}
