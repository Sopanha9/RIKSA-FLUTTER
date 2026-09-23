import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/riksa_profile_drawer.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _user = AuthUser(
  id: 'user-1',
  username: 'sokha',
  displayName: 'Sokha Chan',
  emailVerified: true,
  phoneVerified: true,
  role: 'STUDENT',
);

final _dashboard = ProfileDashboardData(
  gamification: const GamificationProfile(
    totalXp: 5630,
    currentStreak: 7,
    highestStreak: 12,
    xpToNext: 370,
  ),
  achievements: List.generate(
    12,
    (index) => ProfileAchievement(
      id: 'achievement-$index',
      name: 'Achievement $index',
      description: '',
      earned: true,
      progress: 1,
      progressMax: 1,
      progressPercent: 100,
      rarity: 'COMMON',
      xpReward: 10,
    ),
  ),
  activities: const [],
);

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(_user);
}

Future<void> _loadFonts() async {
  final redditSans = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
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
  await Future.wait([redditSans.load(), khmer.load(), materialIcons.load()]);
}

Widget _previewApp(ThemeData theme) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_SignedInAuth.new),
    profileDashboardProvider.overrideWith((ref) async => _dashboard),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: const Scaffold(drawer: RiksaProfileDrawer(), body: SizedBox.shrink()),
  ),
);

void main() {
  setUpAll(_loadFonts);
  // The drawer reads the locally stored avatar path, which goes through
  // SharedPreferences and has no platform implementation under flutter test.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (name, theme) in [
    ('en_light', AppTheme.light),
    ('en_dark', AppTheme.dark),
  ]) {
    testWidgets('profile drawer $name', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_previewApp(theme));
      await tester.pumpAndSettle();
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(RiksaProfileDrawer),
        matchesGoldenFile('goldens/profile_drawer_$name.png'),
      );
    });
  }
}
