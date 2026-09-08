import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_achievement_image.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/presentation/public_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import '../../../visuals/achievement_preview.dart';

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
  avatarUrl: '/avatars/avatar-17.png',
  bio: 'Learning in public.',
  isVerified: true,
  totalXp: 2400,
  currentTier: 'SCHOLAR',
  achievements: [
    PublicProfileAchievement(
      id: 'achievement-1',
      name: 'Study Starter',
      iconUrl: '/icons/ach-first-lesson.png',
      description: 'Completed a first lesson.',
      rarity: 'RARE',
      unlockedAt: null,
    ),
  ],
  rank: PublicProfileRank(countryRank: 42, provinceRank: 5),
);

void main() {
  setUpAll(_loadFonts);
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('public achievement tab at 360px dark=$dark scale=$scale', (
        tester,
      ) async {
        await _pump(
          tester,
          profiles: _Profiles(result: Future.value(_profile)),
          theme: dark ? AppTheme.dark : AppTheme.light,
          width: 360,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        final tab = find.byKey(const ValueKey('profile-achievements-tab'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(RiksaAchievementImage));
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/achievements/ach-first-lesson.png'),
            tester.element(find.byType(RiksaAchievementImage)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Study Starter'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await exportAchievementPreview(
          tester,
          find.byKey(const ValueKey('public-achievement-preview')),
          'public_${dark ? 'dark' : 'light'}_${scale.toInt()}x',
        );
      });
    }
  }

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
    expect(
      find.byKey(const ValueKey('humation-avatar-avatar-17.svg')),
      findsOneWidget,
    );
    expect(find.textContaining('private@example.test'), findsNothing);
    expect(find.textContaining('+855'), findsNothing);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('public-profile-scaffold')),
    );
    expect(scaffold.backgroundColor, AppColors.editorialNeutralCanvas);
    final cover = tester.widget<Container>(
      find.byKey(const ValueKey('public-profile-default-cover')),
    );
    expect(cover.color, AppColors.editorialPinkSoft);
    final avatarRing = tester.widget<Container>(
      find.byKey(const ValueKey('public-profile-avatar-ring')),
    );
    final avatarDecoration = avatarRing.decoration! as BoxDecoration;
    // The ring is painted in the page ground so the avatar reads clear of the
    // banner, whatever the banner shows.
    expect(avatarDecoration.color, AppColors.editorialNeutralCanvas);
    expect(
      avatarDecoration.border!.top.color,
      AppColors.editorialNeutralCanvas,
    );
    final verification = tester.widget<Icon>(
      find.byKey(const ValueKey('public-verification-badge')),
    );
    expect(verification.color, AppColors.editorialPink);
    final selectedTab = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('profile-posts-tab')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (selectedTab.decoration! as BoxDecoration).color,
      AppColors.editorialAubergine,
    );

    await tester.tap(find.byKey(const ValueKey('profile-achievements-tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Study Starter'), findsOneWidget);
    expect(
      tester
          .widget<RiksaAchievementImage>(find.byType(RiksaAchievementImage))
          .iconUrl,
      '/icons/ach-first-lesson.png',
    );
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

  testWidgets('never renders a blank public identity', (tester) async {
    const blankIdentity = PublicProfile(
      id: 'user-2',
      username: '',
      displayName: '',
      avatarUrl: null,
      bio: null,
      isVerified: false,
      totalXp: 3250,
      currentTier: 'DIAMOND',
      achievements: [],
      rank: null,
    );

    await _pump(
      tester,
      profiles: _Profiles(result: Future.value(blankIdentity)),
    );
    await tester.pumpAndSettle();

    expect(find.text('@'), findsNothing);
    expect(find.text('RIKSA Learner'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    // A tier on the known ladder draws the rail.
    expect(find.byKey(const ValueKey('public-tier-rail')), findsOneWidget);
  });

  testWidgets('skips the tier rail for a tier off the known ladder', (
    tester,
  ) async {
    // The main fixture reports 'SCHOLAR', which the ladder does not carry.
    // The panel degrades to the name and XP rather than drawing a rail with
    // nothing marked on it.
    await _pump(tester, profiles: _Profiles(result: Future.value(_profile)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('public-tier-rail')), findsNothing);
    expect(find.text('Scholar'), findsOneWidget);
  });

  testWidgets('uses the matching post author when profile identity is blank', (
    tester,
  ) async {
    const blankIdentity = PublicProfile(
      id: 'user-2',
      username: '',
      displayName: '',
      avatarUrl: null,
      bio: null,
      isVerified: false,
      totalXp: 3250,
      currentTier: 'DIAMOND',
      achievements: [],
      rank: null,
    );
    final postWithAuthorAvatar = SocialPost(
      id: _post.id,
      title: _post.title,
      content: _post.content,
      reactionCount: _post.reactionCount,
      commentCount: _post.commentCount,
      shareCount: _post.shareCount,
      author: const SocialAuthor(
        id: 'user-2',
        username: 'dara',
        displayName: 'Dara Seng',
        avatarUrl: '/avatars/avatar-12.png',
      ),
      category: _post.category,
      createdAt: _post.createdAt,
      updatedAt: _post.updatedAt,
    );

    await _pump(
      tester,
      profiles: _Profiles(result: Future.value(blankIdentity)),
      social: _Social(page: _page([postWithAuthorAvatar])),
    );
    await tester.pumpAndSettle();

    expect(find.text('RIKSA Learner'), findsNothing);
    expect(find.text('Dara Seng'), findsWidgets);
    expect(find.text('@dara'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('public-profile-avatar-ring')),
        matching: find.byKey(const ValueKey('humation-avatar-avatar-12.svg')),
      ),
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

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profile-achievements-tab')),
        matching: find.text('សមិទ្ធផល'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the editorial public profile visual', (tester) async {
    await _pump(
      tester,
      profiles: _Profiles(result: Future.value(_profile)),
      social: _Social(page: _page([_post])),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PublicProfileScreen),
      matchesGoldenFile(
        '../../../visuals/goldens/public_profile_editorial_en_light.png',
      ),
    );
  });
}

Future<void> _loadFonts() async {
  final poppins = FontLoader(RiksaTypography.latinFamily);
  for (final name in [
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
  }
  final khmer = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([poppins.load(), khmer.load(), materialIcons.load()]);
}

SocialFeedPage _page(List<SocialPost> posts) =>
    SocialFeedPage(posts: posts, hasNextPage: false);

Future<void> _pump(
  WidgetTester tester, {
  required _Profiles profiles,
  _Social? social,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  double width = 430,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, width == 430 ? 932 : 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        // Reading a stranger's profile: no session, so no owner controls.
        currentUserIdProvider.overrideWithValue(null),
        publicProfileRepositoryProvider.overrideWithValue(profiles),
        publicProfileSocialRepositoryProvider.overrideWithValue(
          social ?? _Social(page: _page(const [])),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: const RepaintBoundary(
          key: ValueKey('public-achievement-preview'),
          child: PublicProfileScreen(userId: 'user-2'),
        ),
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
