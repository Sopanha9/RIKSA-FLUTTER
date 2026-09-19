import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/leaderBoard/presentation/leaderboard_screen.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Future<void> _loadFonts() async {
  final redditSans = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/RedditSans-Variable.ttf'));

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
  await Future.wait([redditSans.load(), materialIcons.load()]);
}

class _PreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'current-user',
      username: 'riksa-admin',
      displayName: 'Riksa Platform Admin',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      provinceId: 'phnom-penh',
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('leaderboard redesign light', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const rows = [
      LeaderboardRow(
        rank: 1,
        userId: 'sokha',
        score: 5630,
        rankingTier: 'LEGEND',
        displayName: 'Sokha Chan',
      ),
      LeaderboardRow(
        rank: 2,
        userId: 'bopha',
        score: 4320,
        rankingTier: 'DIAMOND',
        displayName: 'Bopha Pich',
      ),
      LeaderboardRow(
        rank: 3,
        userId: 'current-user',
        score: 4120,
        rankingTier: 'DIAMOND',
        displayName: 'Riksa Platform Admin',
      ),
      LeaderboardRow(
        rank: 4,
        userId: 'sophea',
        score: 3975,
        rankingTier: 'DIAMOND',
        displayName: 'Teacher Sophea',
      ),
      LeaderboardRow(
        rank: 5,
        userId: 'dara',
        score: 3355,
        rankingTier: 'DIAMOND',
        displayName: 'Dara Seng',
      ),
      LeaderboardRow(
        rank: 6,
        userId: 'demo',
        score: 2980,
        rankingTier: 'DIAMOND',
        displayName: 'Demo Student',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_PreviewAuthNotifier.new),
          profileRankProvider.overrideWith(
            (ref) async => const LeaderboardRank(
              countryRank: 3,
              countryScore: 4120,
              countryTier: 'DIAMOND',
              provinceRank: 2,
              provinceScore: 4120,
              provinceTier: 'DIAMOND',
            ),
          ),
          leaderboardProvider.overrideWith((ref, scope) async => rows),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: Scaffold(
            extendBody: false,
            body: const LeaderboardScreen(),
            bottomNavigationBar: RiksaBottomNavigationBar(
              currentIndex: 3,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LeaderboardScreen));
    await tester.runAsync(() async {
      for (final tier in profileTierLadder) {
        await precacheImage(
          AssetImage('assets/images/ranks/${tier.toLowerCase()}.png'),
          context,
          onError: (error, stack) => fail('Badge failed to load: $error'),
        );
        await precacheImage(
          AssetImage('assets/images/avatar_frames/${tier.toLowerCase()}.png'),
          context,
          onError: (error, stack) => fail('Frame failed to load: $error'),
        );
      }
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    await expectLater(
      find.byType(LeaderboardScreen),
      matchesGoldenFile('goldens/leaderboard_redesign_en_light.png'),
    );
  });
}
