import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/subject_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
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
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([redditSans.load(), materialIcons.load()]);
}

/// The real `GET /lessons/roadmap` response for Grade 12 Mathematics, captured
/// from the running backend. Drawing the golden from the server's own payload
/// means the reference image cannot drift from what the app really renders.
LearningRoadmap _roadmap() => LearningRoadmap.fromJson(
  jsonDecode(
        File(
          'test/fixtures/lessons_roadmap_mathematics.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Future<void> _pumpRoadmap(WidgetTester tester, {required Brightness theme}) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRoadmapProvider(
            'math',
          ).overrideWith((ref) async => _roadmap()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme == Brightness.dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const LearningRoadmapScreen(categoryId: 'math'),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  for (final (name, brightness) in [
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('subject roadmap $name', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpRoadmap(tester, theme: brightness);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(LearningRoadmapScreen),
        matchesGoldenFile('goldens/subject_roadmap_en_$name.png'),
      );
    });
  }
}
