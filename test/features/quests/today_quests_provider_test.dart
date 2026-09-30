import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/quests/data/quest_models.dart';
import 'package:riksa_app/features/quests/data/quests_api.dart';
import 'package:riksa_app/features/quests/providers/today_quests_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';

void main() {
  test('parses the daily quest contract and claim state', () {
    final quests = TodayQuests.fromJson({
      'date': '2026-09-24',
      'resetsAt': '2026-09-25T00:00:00+07:00',
      'allClaimedBonusXp': 30,
      'quests': [
        {
          'id': 'quest-1',
          'type': 'CORRECT_ANSWERS',
          'title': 'Get 3 answers right',
          'titleKm': 'ឆ្លើយត្រូវ ៣ សំណួរ',
          'target': 3,
          'progress': 3,
          'xpReward': 15,
          'completed': true,
          'claimed': false,
        },
      ],
    });

    expect(quests.date, DateTime(2026, 9, 24));
    expect(quests.resetsAt, DateTime.parse('2026-09-25T00:00:00+07:00'));
    expect(quests.allClaimedBonusXp, 30);
    expect(quests.quests.single.type, DailyQuestType.correctAnswers);
    expect(quests.quests.single.claimable, isTrue);
  });

  test('claim action updates the quest and refreshes the profile', () async {
    final repository = _FakeQuestsRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        questsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(todayQuestsProvider.future);
    await container.read(todayQuestsProvider.notifier).claim('quest-1');

    expect(repository.claimedIds, ['quest-1']);
    await container.read(todayQuestsProvider.future);
    expect(
      container.read(todayQuestsProvider).value!.quests.single.claimed,
      isTrue,
    );
    expect(repository.todayCalls, 2);
  });

  test('failed claim restores the previous quest state', () async {
    final repository = _FakeQuestsRepository()..failClaim = true;
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        questsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(todayQuestsProvider.future);
    await expectLater(
      container.read(todayQuestsProvider.notifier).claim('quest-1'),
      throwsStateError,
    );

    expect(
      container.read(todayQuestsProvider).value!.quests.single.claimed,
      isFalse,
    );
  });

  test('guest quest preview remains local and has all three types', () {
    final preview = TodayQuests.guestPreview(titles: const ['a', 'b', 'c']);

    expect(preview.quests.map((quest) => quest.type), DailyQuestType.values);
    expect(preview.allClaimedBonusXp, 30);
    expect(preview.claimableCount, 1);
  });

  test('parses weekly quests and the chest contract', () {
    final week = WeeklyQuests.fromJson({
      'weekStart': '2026-09-21T00:00:00+07:00',
      'resetsAt': '2026-09-28T00:00:00+07:00',
      'quests': [
        {
          'id': 'week-quest-1',
          'type': 'WEEKLY_CORRECT_ANSWERS',
          'title': 'Answer 15 questions',
          'titleKm': 'ឆ្លើយសំណួរ ១៥',
          'target': 15,
          'progress': 15,
          'xpReward': 35,
          'completed': true,
          'claimed': false,
        },
      ],
      'chest': {
        'id': 'chest-1',
        'points': 15,
        'target': 15,
        'maxPoints': 20,
        'opened': false,
        'xpReward': 50,
        'rewardItem': {
          'id': 'hat-1',
          'slot': 'HAT',
          'assetKey': 'hat.sprout',
          'name': 'Sprout cap',
          'nameKm': 'មួកស្លឹក',
        },
      },
    });

    expect(week.resetsAt, DateTime.parse('2026-09-28T00:00:00+07:00'));
    expect(week.claimableCount, 1);
    expect(week.quests.single.type, WeeklyQuestType.correctAnswers);
    expect(week.chest.openable, isTrue);
    expect(week.chest.rewardItem?.assetKey, 'hat.sprout');
  });

  test('weekly claim refreshes today, week, and the profile', () async {
    final repository = _FakeQuestsRepository();
    var profileCalls = 0;
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        questsRepositoryProvider.overrideWithValue(repository),
        profileDashboardProvider.overrideWith((ref) async {
          profileCalls++;
          return const ProfileDashboardData(
            gamification: GamificationProfile(
              totalXp: 0,
              currentStreak: 3,
              highestStreak: 3,
              xpToNext: 100,
            ),
            achievements: [],
            activities: [],
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(todayQuestsProvider.future);
    await container.read(weeklyQuestsProvider.future);
    await container.read(profileDashboardProvider.future);
    await container.read(todayQuestsProvider.notifier).claim('week-quest-1');
    await container.read(todayQuestsProvider.future);
    await container.read(weeklyQuestsProvider.future);
    await container.read(profileDashboardProvider.future);

    expect(repository.weeklyClaimedIds, ['week-quest-1']);
    expect(
      container.read(weeklyQuestsProvider).value!.quests.single.claimed,
      isTrue,
    );
    expect(repository.todayCalls, 2);
    expect(repository.weekCalls, 2);
    expect(profileCalls, 2);
  });

  test('opens a ready weekly chest and preserves the item reward', () async {
    final repository = _FakeQuestsRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        questsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weeklyQuestsProvider.future);
    await container.read(weeklyQuestsProvider.notifier).openChest();
    await container.read(weeklyQuestsProvider.future);

    expect(repository.chestOpenCalls, 1);
    expect(container.read(weeklyQuestsProvider).value!.chest.opened, isTrue);
    expect(
      container.read(weeklyQuestsProvider).value!.chest.rewardItem?.name,
      'Sprout cap',
    );
  });

  test('a 409 chest response restores the unopened ready chest', () async {
    final repository = _FakeQuestsRepository()..failChestOpen = true;
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('learner-1'),
        questsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weeklyQuestsProvider.future);
    await expectLater(
      container.read(weeklyQuestsProvider.notifier).openChest(),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          409,
        ),
      ),
    );

    expect(container.read(weeklyQuestsProvider).value!.chest.openable, isTrue);
  });
}

class _FakeQuestsRepository
    implements QuestsRepository, WeeklyQuestsRepository {
  int todayCalls = 0;
  int weekCalls = 0;
  int chestOpenCalls = 0;
  final List<String> claimedIds = [];
  final List<String> weeklyClaimedIds = [];
  bool failClaim = false;
  bool failChestOpen = false;
  bool _dailyClaimed = false;
  bool _weeklyClaimed = false;
  bool _chestOpened = false;

  @override
  Future<TodayQuests> today() async {
    todayCalls++;
    return TodayQuests(
      date: DateTime(2026, 9, 24),
      resetsAt: DateTime(2026, 9, 25),
      allClaimedBonusXp: 30,
      quests: [_quest(claimed: _dailyClaimed)],
    );
  }

  @override
  Future<DailyQuest> claim(String id) async {
    if (failClaim) throw StateError('claim failed');
    claimedIds.add(id);
    _dailyClaimed = true;
    return _quest(claimed: true);
  }

  @override
  Future<WeeklyQuests> week() async {
    weekCalls++;
    return WeeklyQuests(
      weekStart: DateTime(2026, 9, 21),
      resetsAt: DateTime(2026, 9, 28),
      quests: [_weeklyQuest(claimed: _weeklyClaimed)],
      chest: _chest(opened: _chestOpened),
    );
  }

  @override
  Future<WeeklyQuest> claimWeekly(String id) async {
    if (failClaim) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quests/$id/claim'),
        response: Response(
          requestOptions: RequestOptions(path: '/quests/$id/claim'),
          statusCode: 409,
        ),
      );
    }
    weeklyClaimedIds.add(id);
    _weeklyClaimed = true;
    return _weeklyQuest(claimed: true);
  }

  @override
  Future<WeeklyChest> openChest() async {
    chestOpenCalls++;
    if (failChestOpen) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quests/chest/open'),
        response: Response(
          requestOptions: RequestOptions(path: '/quests/chest/open'),
          statusCode: 409,
        ),
      );
    }
    _chestOpened = true;
    return _chest(opened: true);
  }

  DailyQuest _quest({bool claimed = false}) => DailyQuest(
    id: 'quest-1',
    type: DailyQuestType.completeLesson,
    title: 'Finish 1 lesson',
    titleKm: 'បញ្ចប់មេរៀន ១',
    target: 1,
    progress: 1,
    xpReward: 20,
    completed: true,
    claimed: claimed,
  );

  WeeklyQuest _weeklyQuest({bool claimed = false}) => WeeklyQuest(
    id: 'week-quest-1',
    type: WeeklyQuestType.lessons,
    title: 'Finish five lessons',
    titleKm: '',
    target: 5,
    progress: 5,
    xpReward: 35,
    completed: true,
    claimed: claimed,
  );

  WeeklyChest _chest({bool opened = false}) => WeeklyChest(
    id: 'chest-1',
    points: 15,
    target: 15,
    maxPoints: 20,
    opened: opened,
    xpReward: 50,
    rewardItem: opened
        ? const WeeklyRewardItem(
            id: 'hat-1',
            slot: 'HAT',
            assetKey: 'hat.sprout',
            name: 'Sprout cap',
            nameKm: 'មួកស្លឹក',
          )
        : null,
  );
}
