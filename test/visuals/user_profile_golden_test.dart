import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/user_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_fonts.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sopheak',
      displayName: 'Sopheak Phan',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      createdAt: DateTime.utc(2026),
    ),
  );
}

void main() {
  setUpAll(loadRiksaGoldenFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('personal profile', (tester) async {
    tester.view.physicalSize = const Size(393, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_Auth.new),
          profileDashboardProvider.overrideWith(
            (ref) async => const ProfileDashboardData(
              gamification: GamificationProfile(
                totalXp: 720,
                currentStreak: 7,
                highestStreak: 12,
                currentTier: 'SILVER',
                nextTier: 'GOLD',
                currentTierMinXp: 0,
                nextTierMinXp: 1000,
                xpToNext: 280,
              ),
              achievements: [],
              activities: [],
            ),
          ),
          userPostsProvider.overrideWith(
            (ref, userId) async =>
                const SocialFeedPage(posts: [], hasNextPage: false),
          ),
          profileRankProvider.overrideWith(
            (ref) async => const LeaderboardRank(
              countryRank: 24,
              countryScore: 720,
              countryTier: 'SILVER',
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const UserProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(UserProfileScreen),
      matchesGoldenFile('goldens/user_profile_en_light.png'),
    );
  });
}
