import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Future<void> _loadRiksaFonts() async {
  final redditSans = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/RedditSans-Variable.ttf'));
  final khmer = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
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
  await Future.wait([redditSans.load(), khmer.load(), materialIcons.load()]);
}

void main() {
  setUpAll(_loadRiksaFonts);

  for (final locale in const [Locale('en'), Locale('km')]) {
    for (final brightness in Brightness.values) {
      final language = locale.languageCode;
      final mode = brightness.name;
      testWidgets('learning components $language $mode golden', (tester) async {
        tester.view.physicalSize = const Size(430, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('km')],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const _ComponentGallery(),
          ),
        );
        await tester.pump();

        await expectLater(
          find.byType(_ComponentGallery),
          matchesGoldenFile('goldens/riksa_components_${language}_$mode.png'),
        );
      });
    }
  }
}

class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final khmer = Localizations.localeOf(context).languageCode == 'km';
    final math = khmer ? 'គណិតវិទ្យា' : 'Mathematics';
    final science = khmer ? 'វិទ្យាសាស្ត្រ' : 'Science';
    final title = khmer
        ? 'រៀនអំពីប្រភាគ និងលេខទសភាគ'
        : 'Fractions and decimals';
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiksaPageHeader(
              title: l10n.learn,
              subtitle: l10n.learningHeaderSubtitle,
              trailing: IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RiksaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DailyMissionCard(
                    eyebrow: l10n.dailyMissionEyebrow,
                    title: title,
                    body: l10n.dailyMissionBody,
                    actionLabel: l10n.startDailyMission,
                    subject: math,
                    onPressed: () {},
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  Text(
                    l10n.subjectFilter,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                  Row(
                    children: [
                      SubjectTile(
                        label: math,
                        subject: math,
                        selected: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: RiksaSpacing.xs),
                      SubjectTile(
                        label: science,
                        subject: science,
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  Text(
                    l10n.recommendedLessons,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                  LessonCard(
                    heroTag: 'golden-lesson',
                    subject: math,
                    title: title,
                    durationLabel: l10n.minutesShort(12),
                    difficultyLabel: l10n.difficultyEasy,
                    exerciseLabel: l10n.exerciseCount(3),
                    progress: .42,
                    completedLabel: l10n.completedLabel,
                    onTap: () {},
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                  ActiveFilterChip(
                    label: l10n.gradeNumber(9),
                    removeSemanticLabel: l10n.removeFilter(l10n.gradeFilter),
                    onRemoved: () {},
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                  const LessonCardSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
