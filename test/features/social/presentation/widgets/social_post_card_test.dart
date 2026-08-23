import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/widgets/social_post_card.dart';

void main() {
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
                  username: 'sophea',
                  displayName: 'Sok Sophea',
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
  });
}
