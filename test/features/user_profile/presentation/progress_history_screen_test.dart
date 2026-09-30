import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/progress_history_screen.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

final _now = DateTime.now();

final _xp = [
  XpActivity(
    id: 'a',
    amount: 34,
    sourceType: 'LESSON_COMPLETION',
    runningBalance: 300,
    createdAt: _now,
    detail: 'Balancing chemical equations',
  ),
  XpActivity(
    id: 'b',
    amount: 40,
    sourceType: 'WEEKLY_QUEST',
    runningBalance: 266,
    createdAt: _now.subtract(const Duration(days: 1)),
    detail: 'Finish 5 lessons',
  ),
];

final _ranks = [
  RankHistoryEntry.fromJson({
    'id': 'r1',
    'scope': 'COUNTRY',
    'oldRank': 'BRONZE',
    'newRank': 'SILVER',
    'changedAt': _now.toIso8601String(),
  }),
];

Widget _app({Locale locale = const Locale('en')}) => ProviderScope(
  overrides: [
    xpHistoryProvider.overrideWith((ref) async => _xp),
    rankHistoryProvider.overrideWith((ref) async => _ranks),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const ProgressHistoryScreen(),
  ),
);

void main() {
  test('rank changes are tier names from the server', () {
    final entry = _ranks.single;
    expect(entry.oldRank, 'BRONZE');
    expect(entry.newRank, 'SILVER');
    expect(entry.isPromotion, isTrue);
  });

  testWidgets('XP rows say what the XP was for, grouped by day', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Balancing chemical equations'), findsOneWidget);
    expect(find.text('Weekly quest'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.byKey(const ValueKey('xp-summary')), findsOneWidget);
  });

  testWidgets('rank changes load and show the new tier', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rank changes'));
    await tester.pumpAndSettle();

    expect(find.text('Ranked up to Silver!'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-history-error')), findsNothing);
  });
}
