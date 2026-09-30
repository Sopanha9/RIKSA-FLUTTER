import 'dart:convert';

import 'package:dio/dio.dart';

import 'fake_riksa_server.dart';

/// One believable student, Sophea, with enough data on every screen that the
/// crawler exercises real content instead of empty or error states.
const kUserId = '00000000-0000-4000-8000-000000000001';
const kOtherUserId = '00000000-0000-4000-8000-000000000002';
const kMathId = '10000000-0000-4000-8000-000000000001';
const kPhysicsId = '10000000-0000-4000-8000-000000000002';
const kLessonId = '20000000-0000-4000-8000-000000000001';
const kLesson2Id = '20000000-0000-4000-8000-000000000002';
const kUnitId = '30000000-0000-4000-8000-000000000001';
const kPostId = '40000000-0000-4000-8000-000000000001';
const kCommentId = '50000000-0000-4000-8000-000000000001';
const kBlogId = '60000000-0000-4000-8000-000000000001';
const kChatId = '70000000-0000-4000-8000-000000000001';
const kCommunityId = '80000000-0000-4000-8000-000000000001';
const kHatId = '90000000-0000-4000-8000-000000000001';

final _now = DateTime.now().toUtc();
String _ago(Duration d) => _now.subtract(d).toIso8601String();

Map<String, Object?> get _author => {
  'id': kOtherUserId,
  'username': 'dara',
  'displayName': 'Dara',
  'avatarUrl': null,
};

Map<String, Object?> get _me => {
  'id': kUserId,
  'username': 'sophea',
  'displayName': 'Sophea',
  'avatarUrl': null,
};

Map<String, Object?> _post(String id, String title, {bool mine = false}) => {
  'id': id,
  'title': title,
  'content': 'How do I remember the quadratic formula? Any tricks?',
  'mediaUrl': null,
  'media': <Object>[],
  'reactionCount': 4,
  'commentCount': 2,
  'shareCount': 0,
  'author': mine ? _me : _author,
  'category': {'id': kCommunityId, 'name': 'Mathematics', 'slug': 'math'},
  'myReaction': null,
  'createdAt': _ago(const Duration(hours: 3)),
  'updatedAt': _ago(const Duration(hours: 3)),
  'kind': 'POST',
};

Map<String, Object?> get _comment => {
  'id': kCommentId,
  'content': 'Sing it to the tune of Pop Goes the Weasel!',
  'author': _author,
  'postId': kPostId,
  'parentId': null,
  'myReaction': null,
  'createdAt': _ago(const Duration(hours: 2)),
  'updatedAt': _ago(const Duration(hours: 2)),
};

Map<String, Object?> _lesson(String id, String title, int position) => {
  'id': id,
  'title': title,
  'description': 'Short read and a reflection.',
  'difficulty': 'EASY',
  'baseXp': 20,
  'categoryId': kMathId,
  'categoryName': 'Mathematics',
  'exerciseCount': 2,
  'completed': position == 1,
  'createdAt': _ago(const Duration(days: 30)),
  'estimatedMinutes': 10,
  'position': position,
};

Map<String, Object?> get _blog => {
  'id': kBlogId,
  'authorId': kUserId,
  'title': 'How I study physics on the bus',
  'content': '## My routine\n\nI read one lesson and write one reflection.',
  'coverUrl': null,
  'status': 'APPROVED',
  'rejectionReason': null,
  'viewCount': 12,
  'likeCount': 3,
  'categoryId': null,
  'liked': false,
  'createdAt': _ago(const Duration(days: 2)),
  'updatedAt': _ago(const Duration(days: 2)),
  'author': _me,
};

Map<String, Object?> _quest(String id, String type, {bool done = false}) => {
  'id': id,
  'type': type,
  'title': 'Finish a lesson',
  'titleKm': 'បញ្ចប់មេរៀនមួយ',
  'target': 1,
  'progress': done ? 1 : 0,
  'xpReward': 10,
  'completed': done,
  'claimed': false,
};

Map<String, Object?> _gql(Map<String, Object?> data) => {'data': data};

String _operation(RequestOptions r) {
  final data = r.data;
  final body = data is String ? jsonDecode(data) : data;
  final query = (body is Map ? body['query'] : null)?.toString() ?? '';
  final named = RegExp(r'(query|mutation)\s+(\w+)').firstMatch(query);
  if (named != null) return named.group(2)!;
  return query.contains('categories') ? 'Categories' : 'Unknown';
}

Object? _graphql(RequestOptions r) {
  final categories = [
    {
      'id': kCommunityId,
      'name': 'Mathematics',
      'slug': 'math',
      'description': 'Algebra, calculus and more',
      'iconUrl': null,
      'memberCount': 120,
      'joined': true,
    },
    {'id': kMathId, 'name': 'Mathematics'},
    {'id': kPhysicsId, 'name': 'Physics'},
  ];
  final page = {
    'pageInfo': {'hasNextPage': false, 'endCursor': null},
    'edges': [
      _post(kPostId, 'Quadratic formula tricks?'),
      _post(
        '40000000-0000-4000-8000-000000000002',
        'My study streak',
        mine: true,
      ),
    ],
  };
  final comments = {
    'pageInfo': {'hasNextPage': false, 'endCursor': null},
    'edges': [_comment],
  };
  return switch (_operation(r)) {
    'Categories' => _gql({'categories': categories}),
    'Feed' => _gql({'feed': page}),
    'Post' => _gql({'post': _post(kPostId, 'Quadratic formula tricks?')}),
    'Comments' || 'CommentReplies' => _gql({'comments': comments}),
    'CreateComment' => _gql({'createComment': _comment}),
    'React' || 'ReactToComment' => _gql({
      'react': _post(kPostId, 'Quadratic formula tricks?'),
    }),
    'Share' => _gql({'sharePost': _post(kPostId, 'Quadratic formula tricks?')}),
    'DeletePost' => _gql({'deletePost': true}),
    'CategoryMembership' => _gql({
      'joinCategory': categories.first,
      'leaveCategory': {...categories.first, 'joined': false},
    }),
    'DeleteComment' => _gql({'deleteComment': true}),
    final other => _gql({other: null}),
  };
}

/// Every endpoint the app calls, answered with the data above.
Map<String, Object?> get _authMe => {
  'id': kUserId,
  'username': 'sophea',
  'displayName': 'Sophea',
  'email': 'sophea@example.com',
  'role': 'USER',
  'provinceId': 'province-phnom-penh',
};

Map<String, Object?> get _buddyMe => {
  'species': 'crocodile',
  'name': 'Croc',
  'chosen': true,
  'energy': 80,
  'bond': 40,
  'balance': 640,
  'equipped': <String, Object?>{},
  'today': <Object>[],
  'updatedAt': _ago(const Duration(hours: 1)),
};

Map<String, Object? Function(RequestOptions)> crawlerRoutes() => {
  'GET /auth/me': (_) => _authMe,
  'PUT /auth/me': (_) => _authMe,
  'POST /auth/logout': (_) => {'message': 'Logged out'},
  'POST /graphql': _graphql,
  'GET /notifications/unread-count': (_) => {'count': 2},
  'GET /notifications': (_) => {
    'items': [
      {
        'id': 'n1',
        'type': 'POST_COMMENT',
        'actor': _author,
        'targetType': 'COMMENT',
        'targetId': kCommentId,
        'postId': kPostId,
        'preview': 'Sing it to the tune of Pop Goes the Weasel!',
        'read': false,
        'createdAt': _ago(const Duration(minutes: 20)),
      },
      {
        'id': 'n2',
        'type': 'BLOG_APPROVED',
        'actor': null,
        'targetType': 'BLOG',
        'targetId': kBlogId,
        'postId': null,
        'preview': 'How I study physics on the bus',
        'read': false,
        'createdAt': _ago(const Duration(hours: 5)),
      },
    ],
    'unreadCount': 2,
    'nextCursor': null,
  },
  'POST /notifications/*/read': (_) => {'count': 1},
  'POST /notifications/read-all': (_) => null,
  'GET /gamification/me': (_) => {
    'totalXp': 1240,
    'xpBalance': 640,
    'currentStreak': 5,
    'highestStreak': 9,
    'currentTier': 'SILVER',
    'currentTierIcon': null,
    'nextTier': 'GOLD',
    'currentTierMinXp': 1000,
    'nextTierMinXp': 2500,
    'xpToNext': 1260,
  },
  'GET /gamification/achievements': (_) => [
    {
      'id': 'a1',
      'name': 'First steps',
      'description': 'Finish your first lesson',
      'iconUrl': null,
      'earned': true,
      'unlockedAt': _ago(const Duration(days: 10)),
      'rarity': 'COMMON',
      'xpReward': 10,
    },
    {
      'id': 'a2',
      'name': 'Week warrior',
      'description': 'Keep a 7-day streak',
      'iconUrl': null,
      'earned': false,
      'progress': 5,
      'progressMax': 7,
      'rarity': 'RARE',
      'xpReward': 50,
    },
  ],
  'GET /gamification/xp': (_) => {
    'edges': [
      {
        'id': 'x1',
        'amount': 20,
        'sourceType': 'LESSON_COMPLETION',
        'sourceId': kLessonId,
        'runningBalance': 1240,
        'createdAt': _ago(const Duration(hours: 1)),
      },
    ],
    'hasNextPage': false,
    'endCursor': null,
  },
  'GET /gamification/rank-history': (_) => {'edges': <Object>[]},
  'GET /gamification/streak': (_) => {
    'currentStreak': 5,
    'highestStreak': 9,
    'activeDates': [
      for (var i = 0; i < 5; i++)
        _now.subtract(Duration(days: i)).toIso8601String().substring(0, 10),
    ],
    'currentMilestoneName': 'Spark',
    'nextMilestoneName': 'Flame',
    'daysToNext': 2,
  },
  'GET /quests/today': (_) => {
    'date': _now.toIso8601String().substring(0, 10),
    'resetsAt': _now.add(const Duration(hours: 8)).toIso8601String(),
    'quests': [
      _quest('q1', 'FINISH_LESSON', done: true),
      _quest('q2', 'ANSWER_EXERCISES'),
    ],
    'allClaimedBonusXp': 15,
  },
  'GET /quests/week': (_) => {
    'weekStart': _now
        .subtract(const Duration(days: 2))
        .toIso8601String()
        .substring(0, 10),
    'resetsAt': _now.add(const Duration(days: 5)).toIso8601String(),
    'quests': [_quest('w1', 'LESSONS_THIS_WEEK')],
    'chest': {
      'id': 'c1',
      'points': 3,
      'target': 5,
      'maxPoints': 5,
      'opened': false,
      'xpReward': 50,
      'rewardItem': null,
    },
  },
  'POST /quests/*/claim': (_) =>
      _quest('q1', 'FINISH_LESSON', done: true)..['claimed'] = true,
  'GET /buddy/me': (_) => _buddyMe,
  'PUT /buddy/me': (_) => _buddyMe,
  'PUT /buddy/me/equipped': (_) => _buddyMe,
  'GET /market/items': (r) => {
    'balance': 640,
    'items': [
      for (final item in _marketItems)
        if (r.queryParameters['slot'] == null ||
            '${r.queryParameters['slot']}'.toUpperCase() == item['slot'])
          item,
    ],
  },
};

final _marketItems = <Map<String, Object?>>[
  {
    'id': kHatId,
    'slot': 'HAT',
    'name': 'Straw hat',
    'nameKm': 'មួកចំបើង',
    'price': 200,
    'rarity': 'COMMON',
    'assetKey': 'straw_hat',
    'owned': true,
    'equipped': false,
    'locked': false,
  },
  {
    'id': '90000000-0000-4000-8000-000000000002',
    'slot': 'EYEWEAR',
    'name': 'Round glasses',
    'nameKm': 'វ៉ែនតាមូល',
    'price': 300,
    'rarity': 'RARE',
    'assetKey': 'round_glasses',
    'owned': false,
    'equipped': false,
    'locked': false,
  },
];

Map<String, Object? Function(RequestOptions)> _moreRoutes() => {
  'GET /leaderboard/me': (_) => {
    'countryRank': 42,
    'countryScore': 1240,
    'countryTier': 'SILVER',
    'provinceRank': 7,
    'provinceScore': 1240,
    'provinceTier': 'SILVER',
  },
  'GET /leaderboard': (_) => [
    for (var i = 1; i <= 5; i++)
      {
        'rank': i,
        'userId': i == 3 ? kUserId : 'u$i',
        'score': 3000 - i * 200,
        'rankingTier': 'GOLD',
        'displayName': i == 3 ? 'Sophea' : 'Student $i',
        'avatarUrl': null,
      },
  ],
  'GET /lessons': (_) => {
    'content': [
      _lesson(kLessonId, 'Quadratic equations', 1),
      _lesson(kLesson2Id, 'The discriminant', 2),
    ],
    'number': 0,
    'size': 20,
    'totalElements': 2,
    'totalPages': 1,
  },
  'GET /lessons/roadmap': (_) => {
    'categoryId': kMathId,
    'categoryName': 'Mathematics',
    'completedLessons': 1,
    'totalLessons': 2,
    'progress': 0.5,
    'currentLessonId': kLesson2Id,
    'activeDates': <Object>[],
    'units': [
      {
        'id': kUnitId,
        'title': 'Unit 1 · Quadratics',
        'description': 'Solve and graph quadratics',
        'position': 1,
        'status': 'IN_PROGRESS',
        'completedLessons': 1,
        'totalLessons': 2,
        'skippable': false,
        'lessons': [
          {
            'id': kLessonId,
            'title': 'Quadratic equations',
            'difficulty': 'EASY',
            'baseXp': 20,
            'estimatedMinutes': 10,
            'exerciseCount': 2,
            'progress': 1,
            'status': 'COMPLETED',
            'current': false,
          },
          {
            'id': kLesson2Id,
            'title': 'The discriminant',
            'difficulty': 'MEDIUM',
            'baseXp': 25,
            'estimatedMinutes': 12,
            'exerciseCount': 2,
            'progress': 0,
            'status': 'AVAILABLE',
            'current': true,
          },
        ],
      },
    ],
  },
  'GET /lessons/*': (_) => {
    'id': kLesson2Id,
    'title': 'The discriminant',
    'description': '## What it tells you\n\nb² − 4ac decides how many roots.',
    'difficulty': 'MEDIUM',
    'baseXp': 25,
    'categoryId': kMathId,
    'categoryName': 'Mathematics',
    'reflectionPrompt':
        'In your own words, what does the discriminant tell you?',
    'exercises': [
      {
        'id': 'e1',
        'question': 'If b² − 4ac < 0, how many real roots are there?',
        'difficulty': 'EASY',
        'points': 5,
        'completed': false,
        'sectionIndex': 0,
        'type': 'MULTIPLE_CHOICE',
        'options': ['0', '1', '2'],
        'hint': 'Think about the square root.',
      },
    ],
  },
  'GET /learning/me/continue': (_) => {
    'allCompleted': false,
    'lesson': {
      'lessonId': kLesson2Id,
      'lessonTitle': 'The discriminant',
      'categoryId': kMathId,
      'categoryName': 'Mathematics',
      'totalExerciseCount': 2,
      'attemptedExerciseCount': 0,
      'correctExerciseCount': 0,
      'progressPercentage': 0,
      'completed': false,
      'canResume': true,
    },
  },
  'GET /learning/lessons/*/resources': (_) => {
    'edges': <Object>[],
    'hasNextPage': false,
  },
  'GET /blog': (_) => {
    'content': [_blog],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
  },
  'GET /blog/my-posts': (_) => {
    'content': [_blog],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
  },
  'GET /blog/*': (_) => _blog,
  'POST /blog/*/like': (_) => _blog..['liked'] = true,
  'POST /blog/*/read-complete': (_) => null,
  'GET /ai/chats': (_) => [
    {
      'id': kChatId,
      'title': 'Help with limits',
      'updatedAt': _ago(const Duration(hours: 4)),
      'messageCount': 2,
    },
  ],
  'GET /ai/chats/*': (_) => {
    'id': kChatId,
    'title': 'Help with limits',
    'updatedAt': _ago(const Duration(hours: 4)),
    'messages': [
      {
        'id': 'm1',
        'role': 'user',
        'content': 'What is a limit?',
        'createdAt': _ago(const Duration(hours: 4)),
      },
      {
        'id': 'm2',
        'role': 'assistant',
        'content': 'A limit is the value a function approaches.',
        'createdAt': _ago(const Duration(hours: 4)),
      },
    ],
  },
  'GET /profiles/*': (_) => {
    'user': _author,
    'gamification': {
      'totalXp': 2100,
      'currentStreak': 3,
      'currentTier': 'GOLD',
    },
    'achievements': <Object>[],
    'rank': {'countryRank': 12, 'provinceRank': 2},
    'coverUrl': null,
  },
  'GET /auth/provinces': (_) => [
    {
      'id': 'province-phnom-penh',
      'nameKhmer': 'ភ្នំពេញ',
      'nameLatin': 'Phnom Penh',
    },
  ],
};

FakeRiksaServer crawlerServer() =>
    FakeRiksaServer({...crawlerRoutes(), ..._moreRoutes()});
