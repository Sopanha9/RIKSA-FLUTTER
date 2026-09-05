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

  testWidgets('opens the post when the card body is tapped', (tester) async {
    await initializeDateFormatting('en');
    var opened = false;
    var authorOpens = 0;
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
                title: 'របៀបរៀនមានប្រសិទ្ធភាព',
                content: r'សង្ខេបមេរៀន។\n\n- រំលឹកឡើងវិញ',
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
              onAuthorTap: () => authorOpens++,
              onReact: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('author-avatar-user-1')));
    expect(authorOpens, 1);
    expect(opened, isFalse);

    await tester.tap(find.byKey(const ValueKey('author-name-user-1')));
    expect(authorOpens, 2);
    expect(opened, isFalse);

    final title = tester.widget<Text>(find.text('របៀបរៀនមានប្រសិទ្ធភាព'));
    final content = tester.widget<Text>(
      find.text('សង្ខេបមេរៀន។\n\n• រំលឹកឡើងវិញ'),
    );
    expect(title.style?.fontFamily, RiksaTypography.khmerBodyFamily);
    expect(content.style?.fontFamily, RiksaTypography.khmerBodyFamily);
    expect(find.textContaining(r'\n'), findsNothing);

    await tester.tap(find.text('របៀបរៀនមានប្រសិទ្ធភាព'));

    expect(opened, isTrue);
    expect(find.byKey(const ValueKey('react-post-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-post-1')), findsOneWidget);
    final outerCard = tester.widget<Material>(
      find.byKey(const ValueKey('post-post-1')),
    );
    expect(
      (outerCard.shape! as RoundedRectangleBorder).borderRadius,
      AppRadii.largeBorder,
    );
  });

  testWidgets('shows the owner menu only when the reader owns the post', (
    tester,
  ) async {
    await initializeDateFormatting('en');
    var edits = 0;
    var deletes = 0;

    Future<void> pump({required bool owned}) => tester.pumpWidget(
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
              post: _ownedPost,
              onTap: () {},
              onReact: () {},
              onShare: () {},
              onEdit: owned ? () => edits++ : null,
              onDelete: owned ? () => deletes++ : null,
            ),
          ),
        ),
      ),
    );

    await pump(owned: false);
    expect(find.byKey(const ValueKey('post-options-post-9')), findsNothing);

    await pump(owned: true);
    final menu = find.byKey(const ValueKey('post-options-post-9'));
    expect(menu, findsOneWidget);

    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit post'));
    await tester.pumpAndSettle();
    expect(edits, 1);

    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });
}

final _ownedPost = SocialPost(
  id: 'post-9',
  title: 'What I learned building a solar oven',
  content: 'Foil, a cardboard box, and one very sunny afternoon.',
  reactionCount: 5,
  commentCount: 1,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'me',
    username: 'sopanha',
    displayName: 'Sopanha',
    avatarUrl: '',
  ),
  category: const SocialCategory(
    id: 'category-1',
    name: 'Science',
    slug: 'science',
    memberCount: 40,
    joined: true,
  ),
  createdAt: DateTime.utc(2026, 8, 22),
  updatedAt: DateTime.utc(2026, 8, 22),
);
