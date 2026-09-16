import 'dart:convert';
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
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_catalog_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

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
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([poppins.load(), materialIcons.load()]);
}

class _SignedInNotifier extends AuthNotifier {
  @override
  AuthState build() => Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sokha',
      email: 'sokha@example.com',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      createdAt: DateTime.utc(2026),
    ),
  );
}

/// Every STEM subject's real `GET /lessons/roadmap` response, captured from the
/// running backend. The home golden is drawn from the same payloads the app
/// receives, so the reference image cannot drift from production behaviour.
SubjectProgress _subject(String slug, String id, String name) =>
    SubjectProgress.fromRoadmap(
      LearningCategory(id: id, name: name),
      LearningRoadmap.fromJson(
        jsonDecode(
              File(
                'test/fixtures/lessons_roadmap_$slug.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      ),
    );

LearningHomeData _home() {
  final subjects = [
    _subject('mathematics', 'math', 'Mathematics'),
    _subject('physics', 'physics', 'Physics'),
    _subject('chemistry', 'chemistry', 'Chemistry'),
    _subject('biology', 'biology', 'Biology'),
  ];
  final resume = subjects.firstWhere(
    (subject) => subject.resumable != null,
    orElse: () => subjects.first,
  );
  return LearningHomeData(
    subjects: subjects,
    resumeSubject: resume.resumable == null ? null : resume,
    resumeLesson: resume.resumable,
  );
}

void main() {
  setUpAll(_loadFonts);

  for (final dark in [false, true]) {
    testWidgets('learning home ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_SignedInNotifier.new),
            learningHomeProvider.overrideWith((ref) async => _home()),
            communityStreakProvider.overrideWith(
              (ref) async => const CommunityStreak(current: 7, highest: 12),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark : AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('km')],
            home: Scaffold(
              extendBody: false,
              body: const LessonCatalogScreen(),
              bottomNavigationBar: RiksaBottomNavigationBar(
                currentIndex: 1,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LessonCatalogScreen));
      await tester.runAsync(() async {
        for (final asset in [
          'assets/images/lessonsCard/issacnewton.png',
          'assets/images/lessonsCard/enstein.png',
          'assets/images/lessonsCard/chemistry.png',
          'assets/images/lessonsCard/bio.png',
          'assets/images/lessonsCard/computer.png',
        ]) {
          await precacheImage(
            AssetImage(asset),
            context,
            onError: (error, stack) =>
                fail('Subject artwork failed to load: $error'),
          );
        }
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(LessonCatalogScreen),
        matchesGoldenFile(
          'goldens/learning_home_en_${dark ? 'dark' : 'light'}.png',
        ),
      );
      // Let delayed work from the screen finish before the next variant runs.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
