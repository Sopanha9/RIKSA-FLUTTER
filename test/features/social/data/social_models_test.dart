import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/social/data/social_models.dart';

void main() {
  test('social markdown previews flatten common markdown structures', () {
    final cases = <({String name, String markdown, String preview})>[
      (
        name: 'bold, italic, asterisks, and underscores',
        markdown: '**bold** _italic_ *star* __under__',
        preview: 'bold italic star under',
      ),
      (
        name: 'links keep their visible text',
        markdown: 'Read [the notes](https://example.org/notes).',
        preview: 'Read the notes.',
      ),
      (
        name: 'images become a photo marker',
        markdown: 'See ![the diagram](https://example.org/image.png).',
        preview: 'See [photo].',
      ),
      (
        name: 'blockquote markers are omitted',
        markdown: '> Keep the units consistent.',
        preview: 'Keep the units consistent.',
      ),
      (
        name: 'numbered lists become bullets',
        markdown: '1. first\n2. second',
        preview: '• first\n• second',
      ),
      (
        name: 'asterisk lists become bullets',
        markdown: '* first\n* second',
        preview: '• first\n• second',
      ),
      (
        name: 'headings retain their text',
        markdown: '# Main\n\n## Follow up',
        preview: 'Main\nFollow up',
      ),
      (
        name: 'code fences keep their contents',
        markdown: '```dart\nfinal answer = 42;\n```',
        preview: 'final answer = 42;',
      ),
      (
        name: 'blank lines collapse to a single break',
        markdown: 'First\n\n\nSecond',
        preview: 'First\nSecond',
      ),
      (
        name: 'Khmer text is preserved',
        markdown: 'សូមពិនិត្យចម្លើយម្ដងទៀត។',
        preview: 'សូមពិនិត្យចម្លើយម្ដងទៀត។',
      ),
    ];

    for (final testCase in cases) {
      expect(
        socialMarkdownPreview(testCase.markdown),
        testCase.preview,
        reason: testCase.name,
      );
    }
  });

  test(
    'old posts default to USER while milestone data parses when present',
    () {
      final legacy = SocialPost.fromJson({
        'id': 'legacy',
        'author': {'id': 'u1', 'displayName': 'Dara'},
        'category': {'id': 'c1', 'name': 'Wins', 'slug': 'wins'},
      });
      final milestone = SocialPost.fromJson({
        'id': 'win',
        'kind': 'MILESTONE',
        'milestone': {
          'type': 'STREAK',
          'title': '7-day streak',
          'titleKm': '៧ ថ្ងៃជាប់គ្នា',
          'value': 7,
        },
        'author': {'id': 'u1', 'displayName': 'Dara'},
        'category': {'id': 'c1', 'name': 'Wins', 'slug': 'wins'},
      });

      expect(legacy.kind, SocialPostKind.user);
      expect(legacy.milestone, isNull);
      expect(milestone.kind, SocialPostKind.milestone);
      expect(milestone.milestone?.type, SocialMilestoneType.streak);
      expect(milestone.milestone?.value, 7);
    },
  );

  test('legacy mediaUrl payloads still expose one media item', () {
    final post = SocialPost.fromJson({
      'id': 'old-photo',
      'mediaUrl': 'old.png',
    });

    expect(post.media, hasLength(1));
    expect(post.media.single.url, 'old.png');
    expect(post.mediaUrl, 'old.png');
    expect(post.hasMedia, isTrue);
  });

  test('new media payloads preserve order and server dimensions', () {
    final post = SocialPost.fromJson({
      'id': 'multi-photo',
      'mediaUrl': 'first.png',
      'media': [
        {'url': 'first.png', 'width': 1200, 'height': 800},
        {'url': 'second.png', 'width': 600, 'height': 900},
      ],
    });

    expect(post.media.map((photo) => photo.url), ['first.png', 'second.png']);
    expect(post.media.first.aspectRatio, 1.5);
    expect(post.media.last.aspectRatio, closeTo(2 / 3, .001));
    expect(post.mediaUrl, 'first.png');
    expect(post.copyWith(reactionCount: 4).media, post.media);
  });

  test('an explicit empty media list clears a stale compatibility URL', () {
    final post = SocialPost.fromJson({'mediaUrl': 'old.png', 'media': []});

    expect(post.media, isEmpty);
    expect(post.mediaUrl, isNull);
    expect(post.hasMedia, isFalse);
  });

  test('SocialFeedPage parses GraphQL feed and reaction state', () {
    final page = SocialFeedPage.fromJson({
      'edges': [
        {
          'id': 'post-1',
          'title': 'A useful study loop',
          'content': 'Recall, check, and explain.',
          'mediaUrl': null,
          'reactionCount': 12,
          'commentCount': 4,
          'shareCount': 2,
          'myReaction': 'UPVOTE',
          'createdAt': '2026-08-22T01:00:00Z',
          'updatedAt': '2026-08-22T01:00:00Z',
          'author': {
            'id': 'user-1',
            'username': 'sophea',
            'displayName': 'Sok Sophea',
            'avatarUrl': '',
          },
          'category': {
            'id': 'category-1',
            'name': 'Study Skills',
            'slug': 'study-skills',
            'memberCount': 148,
            'joined': true,
          },
        },
      ],
      'pageInfo': {'hasNextPage': true, 'endCursor': 'post-1'},
    });

    expect(page.posts, hasLength(1));
    expect(page.posts.single.myReaction, SocialReaction.upvote);
    expect(page.posts.single.category.memberCount, 148);
    expect(page.hasNextPage, isTrue);
    expect(page.endCursor, 'post-1');
  });

  test('CommunityStreak parses the gamification summary', () {
    final streak = CommunityStreak.fromJson({
      'currentStreak': 7,
      'highestStreak': 12,
      'currentMilestoneName': 'Week Warrior',
      'nextMilestoneName': 'Two Week Streak',
      'daysToNext': 7,
      'lastTrackedDate': '2026-08-22',
      'activityDates': ['2026-08-20', '2026-08-21', '2026-08-22'],
    });

    expect(streak.current, 7);
    expect(streak.highest, 12);
    expect(streak.nextMilestoneName, 'Two Week Streak');
    expect(streak.daysToNext, 7);
    expect(streak.lastTrackedDate, DateTime(2026, 8, 22));
    expect(streak.activityDates, hasLength(3));
    expect(streak.activityDates!.last, DateTime(2026, 8, 22));
  });

  test('CommunityStreak normalizes missing legacy activity history', () {
    const streak = CommunityStreak(current: 3, highest: 5, activityDates: null);

    expect(streak.activityDates ?? const <DateTime>[], isEmpty);
  });

  test('SocialCommentPage parses a discussion page', () {
    final page = SocialCommentPage.fromJson({
      'edges': [
        {
          'id': 'comment-1',
          'content': 'This helped me remember the concept.',
          'postId': 'post-1',
          'parentId': null,
          'myReaction': null,
          'createdAt': '2026-08-22T02:00:00Z',
          'updatedAt': '2026-08-22T02:00:00Z',
          'author': {
            'id': 'user-3',
            'username': 'dara',
            'displayName': 'Dara',
            'avatarUrl': '',
          },
        },
      ],
      'pageInfo': {'hasNextPage': false, 'endCursor': 'comment-1'},
    });

    expect(page.comments, hasLength(1));
    expect(page.comments.single.postId, 'post-1');
    expect(page.comments.single.author.displayName, 'Dara');
    expect(page.comments.single.content, contains('remember'));
    expect(page.hasNextPage, isFalse);
  });
}
