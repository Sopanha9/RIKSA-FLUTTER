import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/widgets/streak_details_sheet.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  required Locale locale,
  required CommunityStreak streak,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showStreakDetailsSheet(context, streak),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final today = DateTime.now();
  final streak = CommunityStreak(
    current: 1,
    highest: 1,
    nextMilestoneName: 'First Day',
    daysToNext: 1,
    lastTrackedDate: today,
    activityDates: [today],
  );

  testWidgets('the Khmer sheet has no hard-coded English', (tester) async {
    await _openSheet(tester, locale: const Locale('km'), streak: streak);

    expect(find.byKey(const ValueKey('streak-details-sheet')), findsOneWidget);
    expect(find.text('Activity history'), findsNothing);
    expect(find.textContaining(' active'), findsNothing);
    expect(find.text('1 ថ្ងៃរៀន'), findsOneWidget);
    expect(find.text('1 ថ្ងៃទៀតដល់ First Day'), findsOneWidget);
  });

  testWidgets('the English sheet explains the next milestone', (tester) async {
    await _openSheet(tester, locale: const Locale('en'), streak: streak);

    expect(find.text('1 learning day'), findsOneWidget);
    expect(find.text('1 day to First Day'), findsOneWidget);
  });

  testWidgets('the sheet is opaque so the page behind cannot show through', (
    tester,
  ) async {
    await _openSheet(tester, locale: const Locale('en'), streak: streak);

    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('streak-details-sheet')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final color = (box.decoration as BoxDecoration).color!;
    expect(color.a, 1);
  });
}
