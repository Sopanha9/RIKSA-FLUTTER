import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/widgets/social_post_card.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('renders streak, rank and unit milestones with usual actions', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('en'), scale: 1);

    expect(find.text('Dara reached a 7-day streak!'), findsOneWidget);
    expect(find.text('Dara reached Silver rank!'), findsOneWidget);
    expect(find.text('Dara finished Unit 1!'), findsOneWidget);
    expect(find.byKey(const ValueKey('post-options-streak')), findsNothing);
    expect(find.byKey(const ValueKey('react-streak')), findsOneWidget);
    expect(find.byKey(const ValueKey('comment-streak')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer celebration cards lay out at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, locale: const Locale('km'), scale: 2);

    expect(
      find.byKey(const ValueKey('milestone-streak-streak')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required double scale,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: ListView(
            children: [
              for (final post in _milestones)
                SocialPostCard(
                  post: post,
                  onTap: () {},
                  onReact: () {},
                  onShare: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);

final _category = const SocialCategory(
  id: 'wins',
  name: 'Wins',
  slug: 'wins',
  memberCount: 0,
  joined: false,
);

final _author = const SocialAuthor(
  id: 'dara',
  username: 'dara',
  displayName: 'Dara',
  avatarUrl: '',
);

final _milestones = [
  _post(
    'streak',
    const SocialMilestone(
      type: SocialMilestoneType.streak,
      title: '7-day streak',
      titleKm: '៧ ថ្ងៃជាប់គ្នា',
      value: 7,
    ),
  ),
  _post(
    'rank',
    const SocialMilestone(
      type: SocialMilestoneType.rankUp,
      title: 'Silver',
      titleKm: 'Silver',
      value: 2,
    ),
  ),
  _post(
    'unit',
    const SocialMilestone(
      type: SocialMilestoneType.unitComplete,
      title: 'Unit 1',
      titleKm: 'ឯកតា ១',
      value: 1,
    ),
  ),
];

SocialPost _post(String id, SocialMilestone milestone) => SocialPost(
  id: id,
  title: milestone.title,
  content: '',
  reactionCount: 2,
  commentCount: 1,
  shareCount: 0,
  author: _author,
  category: _category,
  createdAt: DateTime.utc(2026, 9, 24),
  updatedAt: DateTime.utc(2026, 9, 24),
  kind: SocialPostKind.milestone,
  milestone: milestone,
);
