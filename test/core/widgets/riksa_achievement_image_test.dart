import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/network/api_config.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_achievement_image.dart';
import 'package:riksa_app/core/widgets/riksa_rank_badge.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/profile_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every seed catalog identifier resolves and every PNG has alpha',
    () async {
      final catalog =
          (jsonDecode(
                    File(
                      'test/fixtures/achievement_catalog.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>();
      expect(catalog, hasLength(31));
      final mapped = {
        ...RiksaAchievementImage.bundledAssets.keys,
        ...RiksaAchievementImage.rankTiers.keys,
      };
      expect(mapped, unorderedEquals(catalog.map((entry) => entry['iconUrl'])));
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final dimensions = <String>{};
      for (final asset in RiksaAchievementImage.bundledAssets.values) {
        expect(manifest.listAssets(), contains(asset));
        final bytes = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        dimensions.add('${image.width}x${image.height}');
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var transparent = 0;
        var opaque = 0;
        for (var i = 3; i < rgba.length; i += 4) {
          if (rgba[i] == 0) transparent++;
          if (rgba[i] >= 240) opaque++;
        }
        expect(
          transparent,
          greaterThan(image.width * image.height * .1),
          reason: asset,
        );
        expect(
          opaque,
          greaterThan(image.width * image.height * .4),
          reason: asset,
        );
        for (final pixel in [
          0,
          image.width - 1,
          (image.height - 1) * image.width,
          image.width * image.height - 1,
        ]) {
          expect(rgba[pixel * 4 + 3], 0, reason: '$asset corner');
        }
        image.dispose();
        codec.dispose();
      }
      expect(dimensions, hasLength(1));
      for (final tier in RiksaAchievementImage.rankTiers.values) {
        expect(
          manifest.listAssets(),
          contains('assets/images/ranks/${tier.toLowerCase()}.png'),
        );
      }
    },
  );

  testWidgets('catalog paths use assets and rank paths reuse the rank widget', (
    tester,
  ) async {
    for (final entry in RiksaAchievementImage.bundledAssets.entries) {
      await tester.pumpWidget(
        _app(RiksaAchievementImage(iconUrl: ' ${entry.key}?v=1 ')),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, AssetImage(entry.value));
      expect(image.fit, BoxFit.contain);
      expect(find.byType(ClipOval), findsNothing);
    }
    for (final entry in RiksaAchievementImage.rankTiers.entries) {
      await tester.pumpWidget(_app(RiksaAchievementImage(iconUrl: entry.key)));
      expect(
        tester.widget<RiksaRankBadge>(find.byType(RiksaRankBadge)).tier,
        entry.value,
      );
    }
  });

  testWidgets('unknown, missing and invalid icons stay neutral', (
    tester,
  ) async {
    for (final value in [
      null,
      '',
      ' ',
      '/icons/ach-future.png',
      'First Lesson',
      'file:///tmp/badge.png',
      'data:image/png;base64,AA',
      'https://',
      'http://[invalid',
    ]) {
      await tester.pumpWidget(_app(RiksaAchievementImage(iconUrl: value)));
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(RiksaRankBadge), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'custom URLs retain their full address and contain fit; failures are neutral',
    (tester) async {
      for (final url in [
        'https://example.test/custom.png?token=abc',
        'http://example.test/icons/ach-first-lesson.png',
      ]) {
        await tester.pumpWidget(_app(RiksaAchievementImage(iconUrl: url)));
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, NetworkImage(url));
        expect(image.fit, BoxFit.contain);
        // The widget-test HTTP client returns 400. Exercise the real error path.
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('relative custom images resolve through API configuration', (
    tester,
  ) async {
    for (final path in [
      '/media/achievement.png?version=2',
      'media/achievement.png',
      'achievement.png',
    ]) {
      await tester.pumpWidget(_app(RiksaAchievementImage(iconUrl: path)));
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        image.image,
        NetworkImage(
          Uri.parse('${ApiConfig.baseUrl}/').resolve(path).toString(),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('valid custom PNG bytes decode successfully', (tester) async {
    const url = 'https://art.example.test/valid-achievement.png';
    final client = _ImageClient();
    final request = _ImageRequest();
    final bytes = File(
      'assets/images/achievements/ach-first-lesson.png',
    ).readAsBytesSync();
    when(() => client.getUrl(Uri.parse(url))).thenAnswer((_) async => request);
    when(() => request.close()).thenAnswer((_) async => _ImageResponse(bytes));
    debugNetworkImageHttpClientProvider = () => client;
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    await tester.pumpWidget(_app(const RiksaAchievementImage(iconUrl: url)));
    final context = tester.element(find.byType(RiksaAchievementImage));
    await tester.runAsync(
      () => precacheImage(
        const NetworkImage(url),
        context,
        onError: (e, _) => fail('$e'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(tester.takeException(), isNull);
    verify(() => client.getUrl(Uri.parse(url))).called(1);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets(
    'card artwork is decorative while standalone labels remain accessible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _app(
            const ProfileAchievementTile(
              name: 'First Lesson',
              description: 'Complete your first lesson',
              iconUrl: '/icons/ach-first-lesson.png',
              trailingLabel: '+20 XP',
            ),
          ),
        );
        expect(find.bySemanticsLabel('First Lesson'), findsOneWidget);
        expect(
          tester
              .widget<RiksaAchievementImage>(find.byType(RiksaAchievementImage))
              .semanticLabel,
          isNull,
        );
        await tester.pumpWidget(
          _app(
            const RiksaAchievementImage(
              iconUrl: null,
              semanticLabel: 'Achievement artwork unavailable',
            ),
          ),
        );
        expect(
          find.bySemanticsLabel('Achievement artwork unavailable'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('cards fit ${width}px at ${scale}x text', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ProfileAchievementGrid(
                    itemCount: 2,
                    itemBuilder: (_, index) => ProfileAchievementTile(
                      name: index == 0
                          ? 'Category Explorer'
                          : 'អ្នកនិពន្ធដែលគេស្រឡាញ់',
                      description:
                          'Complete at least one lesson in every category. A longer backend description remains readable.',
                      iconUrl: '/icons/ach-explorer.png',
                      trailingLabel: index == 0 ? '+2000 XP' : 'LEGENDARY',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cards = find.byType(ProfileAchievementTile);
        expect(cards, findsNWidgets(2));
        if (scale == 2 || width == 320) {
          expect(
            tester.getTopLeft(cards.at(1)).dy,
            greaterThan(tester.getBottomLeft(cards.at(0)).dy),
          );
        }
      });
    }
  }
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

class _ImageClient extends Mock implements HttpClient {}

class _ImageRequest extends Mock implements HttpClientRequest {}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse(this.bytes);
  final List<int> bytes;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
