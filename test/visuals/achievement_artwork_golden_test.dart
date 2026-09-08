import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_achievement_image.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/profile_ui.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Poppins': 'assets/fonts/Poppins-Regular.ttf',
      'Kantumruy Pro': 'assets/fonts/KantumruyPro-Variable.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            File(entry.value).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });

  testWidgets('collection at 32 and 48 on light and dark surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1136);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog =
        (jsonDecode(
                  File(
                    'test/fixtures/achievement_catalog.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final names = {
      for (final entry in catalog)
        entry['iconUrl'] as String: entry['name'] as String,
    };
    final icons = [
      ...RiksaAchievementImage.bundledAssets.keys,
      ...RiksaAchievementImage.rankTiers.keys,
    ];
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('achievement-collection'),
            child: ColoredBox(
              color: AppTheme.light.scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riksa achievements',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '31 collectibles · each shown at 32 and 48 px on light and dark surfaces',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final icon in icons)
                          SizedBox(
                            width: 200,
                            height: 136,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  names[icon]!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                for (final theme in [
                                  AppTheme.light,
                                  AppTheme.dark,
                                ])
                                  Theme(
                                    data: theme,
                                    child: ColoredBox(
                                      color: theme.scaffoldBackgroundColor,
                                      child: SizedBox(
                                        height: 52,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            for (final size in [32.0, 48.0])
                                              RiksaAchievementImage(
                                                iconUrl: icon,
                                                size: size,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _precache(tester);
    expect(tester.takeException(), isNull);
    await _verify(tester, 'achievement-collection', 'achievement_collection');
  });

  testWidgets('achievement cards on narrow screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('achievement-cards'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final theme in [AppTheme.light, AppTheme.dark])
                  Theme(
                    data: theme,
                    child: Builder(
                      builder: (context) => ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: SizedBox(
                          width: 360,
                          height: 1000,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '360 px · default text',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ProfileAchievementGrid(
                                  itemCount: 2,
                                  itemBuilder: (_, i) => ProfileAchievementTile(
                                    name: i == 0
                                        ? 'First Lesson'
                                        : 'Legend Tier',
                                    description: i == 0
                                        ? 'Complete your first lesson'
                                        : 'Reach Legend rank',
                                    iconUrl: i == 0
                                        ? '/icons/ach-first-lesson.png'
                                        : '/icons/ach-rank-legend.png',
                                    trailingLabel: i == 0
                                        ? '+20 XP'
                                        : 'Legendary',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '360 px · 200% text',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: const TextScaler.linear(2),
                                  ),
                                  child: ProfileAchievementGrid(
                                    itemCount: 2,
                                    itemBuilder: (_, i) => ProfileAchievementTile(
                                      name: i == 0
                                          ? 'Category Explorer'
                                          : 'Beloved Author',
                                      description: i == 0
                                          ? 'Complete at least one lesson in every category'
                                          : 'Receive 100 likes on your blog posts',
                                      iconUrl: i == 0
                                          ? '/icons/ach-explorer.png'
                                          : '/icons/ach-beloved.png',
                                      trailingLabel: i == 0
                                          ? '+200 XP'
                                          : 'Legendary',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await _precache(tester);
    expect(tester.takeException(), isNull);
    await _verify(tester, 'achievement-cards', 'achievement_cards');
  });
}

Future<void> _precache(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold));
  await tester.runAsync(() async {
    for (final asset in [
      ...RiksaAchievementImage.bundledAssets.values,
      for (final tier in RiksaAchievementImage.rankTiers.values)
        'assets/images/ranks/${tier.toLowerCase()}.png',
    ]) {
      await precacheImage(
        AssetImage(asset),
        context,
        onError: (error, _) => fail('$asset: $error'),
      );
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _verify(WidgetTester tester, String key, String name) async {
  final finder = find.byKey(ValueKey(key));
  // Export for human inspection BEFORE accepting a new or changed golden.
  if (Platform.environment['EXPORT_ACHIEVEMENT_PREVIEWS'] == '1') {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/achievement-artwork/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } else {
    await expectLater(finder, matchesGoldenFile('goldens/$name.png'));
  }
}
