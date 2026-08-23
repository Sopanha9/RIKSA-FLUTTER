import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/social/data/social_models.dart';

void main() {
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
