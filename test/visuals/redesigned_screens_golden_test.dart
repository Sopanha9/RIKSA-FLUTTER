import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/presentation/blog_feed_screen.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
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

class _PreviewBlogNotifier extends BlogFeedNotifier {
  @override
  BlogFeedState build() => BlogFeedLoaded(
    posts: [
      BlogPost(
        id: 'preview-story',
        authorId: 'riksa-learner',
        title: 'Five small habits that make learning stick',
        content:
            'Build a gentle routine, review what matters, and leave space '
            'for curiosity. Consistent practice turns small steps into real '
            'progress.',
        status: BlogStatus.approved,
        viewCount: 128,
        likeCount: 24,
        categoryId: 'study-skills',
        liked: true,
        createdAt: DateTime(2026, 8, 24),
        updatedAt: DateTime(2026, 8, 24),
      ),
      BlogPost(
        id: 'preview-science',
        authorId: 'riksa-learner-2',
        title: 'Science is everywhere in a Cambodian kitchen',
        content:
            'Heat, texture, fermentation, and timing make everyday cooking '
            'a practical science lesson.',
        status: BlogStatus.approved,
        viewCount: 86,
        likeCount: 18,
        categoryId: 'science',
        liked: false,
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      ),
    ],
    page: 0,
    totalPages: 1,
  );
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: home,
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('story feed preview', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blogFeedProvider.overrideWith(_PreviewBlogNotifier.new),
          blogCategoriesProvider.overrideWith(
            (ref) async => [
              BlogCategory(
                id: 'study-skills',
                name: 'Study skills',
                slug: 'study-skills',
                memberCount: 120,
                joined: true,
              ),
              BlogCategory(
                id: 'science',
                name: 'Science',
                slug: 'science',
                memberCount: 84,
                joined: false,
              ),
            ],
          ),
        ],
        child: _localizedApp(const BlogFeedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BlogFeedScreen),
      matchesGoldenFile('goldens/story_feed_en_light.png'),
    );
  });
}
