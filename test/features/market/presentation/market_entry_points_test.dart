import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_panel/buddy_panel_content.dart';
import 'package:riksa_app/features/quests/data/quest_models.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('buddy panel footer navigates to the market', (tester) async {
    final paths = <String>[];
    await tester.pumpWidget(
      _panel(isGuest: true, week: _weekPreview(), onNavigate: paths.add),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const ValueKey('buddy-market-entry'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);

    expect(paths, ['/market']);
  });

  testWidgets('weekly chest reward links to the wardrobe', (tester) async {
    final paths = <String>[];
    final chest = WeeklyQuests(
      weekStart: null,
      resetsAt: null,
      quests: const [],
      chest: const WeeklyChest(
        id: 'week-1',
        points: 15,
        target: 15,
        maxPoints: 15,
        opened: true,
        xpReward: 50,
        rewardItem: WeeklyRewardItem(
          id: 'straw-hat',
          slot: 'HAT',
          assetKey: 'hat_straw',
          name: 'Straw hat',
          nameKm: 'មួកចំបើង',
        ),
      ),
    );
    await tester.pumpWidget(
      _panel(isGuest: true, week: chest, onNavigate: paths.add),
    );
    await tester.pumpAndSettle();
    final wear = find.text('You got Straw hat! Wear it');
    await tester.ensureVisible(wear);
    await tester.tap(wear);

    expect(paths, ['/market/wardrobe']);
  });
}

WeeklyQuests _weekPreview() => WeeklyQuests.guestPreview(
  titles: const ['Lessons', 'Answers', 'Active days', 'Community'],
  showLockedActions: false,
);

Widget _panel({
  required bool isGuest,
  required WeeklyQuests week,
  required ValueChanged<String> onNavigate,
}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: Scaffold(
      body: BuddyPanelContent(
        isGuest: isGuest,
        todayPreview: TodayQuests.guestPreview(
          titles: const ['Read', 'Practice', 'Share'],
          showLockedActions: false,
        ),
        weekPreview: week,
        initialStreak: 0,
        maxHeight: 1200,
        requireAccountAction: (reason) => false,
        onNavigate: onNavigate,
        onClose: () {},
      ),
    ),
  ),
);
