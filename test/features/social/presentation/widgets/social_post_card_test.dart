import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/widgets/social_post_card.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  test('derives stable, varied avatar colors from the author seed', () {
    expect(socialAvatarPalette('bopha'), socialAvatarPalette('bopha'));
    expect(socialAvatarPalette('bopha'), isNot(socialAvatarPalette('sokha')));
  });

  test('recognizes the reserved RIKSA admin account', () {
    expect(
      isOfficialRiksaAuthor(
        const SocialAuthor(
          id: 'admin-1',
          username: 'riksa.admin',
          displayName: 'Riksa Admin',
          avatarUrl: '',
        ),
      ),
      isTrue,
    );
    expect(
      isOfficialRiksaAuthor(
        const SocialAuthor(
          id: 'user-1',
          username: 'riksa.student',
          displayName: 'Riksa Student',
          avatarUrl: '',
        ),
      ),
      isFalse,
    );
  });

  test('maps core RIKSA categories to compact metadata prefixes', () {
    const cases = <String, String>{
      'Mathematics': 'math/',
      'Biology': 'bio/',
      'Chemistry': 'chem/',
      'Computer Science': 'cs/',
      'Study Skills': 'study/',
    };

    for (final entry in cases.entries) {
      expect(
        categoryPrefix(
          SocialCategory(
            id: entry.key,
            name: entry.key,
            slug: entry.key.toLowerCase().replaceAll(' ', '-'),
            memberCount: 0,
            joined: false,
          ),
        ),
        entry.value,
      );
    }
  });

  testWidgets('opens the post when the card body is tapped', (tester) async {
    await initializeDateFormatting('en');
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocialPostCard(
              post: SocialPost(
                id: 'post-1',
                title: 'A useful study loop',
                content: 'Recall, check, and explain.',
                reactionCount: 12,
                commentCount: 4,
                shareCount: 2,
                author: const SocialAuthor(
                  id: 'user-1',
                  username: 'riksa.admin',
                  displayName: 'Riksa Admin',
                  avatarUrl: '',
                ),
                category: const SocialCategory(
                  id: 'category-1',
                  name: 'Study Skills',
                  slug: 'study-skills',
                  memberCount: 148,
                  joined: true,
                ),
                createdAt: DateTime.utc(2026, 8, 22),
                updatedAt: DateTime.utc(2026, 8, 22),
              ),
              onTap: () => opened = true,
              onReact: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('A useful study loop'));

    expect(opened, isTrue);
    expect(
      find.byKey(const ValueKey('official-account-badge')),
      findsOneWidget,
    );
    expect(find.text('Official'), findsOneWidget);

    final reaction = find.byKey(const ValueKey('react-post-1'));
    final reactionMaterials = tester.widgetList<Material>(
      find.descendant(of: reaction, matching: find.byType(Material)),
    );
    expect(reactionMaterials, isNotEmpty);
    expect(
      reactionMaterials.every(
        (material) => material.color == Colors.transparent,
      ),
      isTrue,
      reason: 'The like action should not render a filled pill background.',
    );
  });
}
