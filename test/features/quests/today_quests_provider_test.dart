import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/quests/data/quest_models.dart';
import 'package:riksa_app/features/quests/data/quests_api.dart';
import 'package:riksa_app/features/quests/providers/today_quests_provider.dart';

void main() {
  test('parses the daily quest contract and claim state', () {
    final quests = TodayQuests.fromJson({
      'date': '2026-09-24',
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
    expect(
      container.read(todayQuestsProvider).value!.quests.single.claimed,
      isTrue,
    );
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
  });
}

class _FakeQuestsRepository implements QuestsRepository {
  int todayCalls = 0;
  final List<String> claimedIds = [];
  bool failClaim = false;

  @override
  Future<TodayQuests> today() async {
    todayCalls++;
    return TodayQuests(
      date: DateTime(2026, 9, 24),
      allClaimedBonusXp: 30,
      quests: [_quest()],
    );
  }

  @override
  Future<DailyQuest> claim(String id) async {
    if (failClaim) throw StateError('claim failed');
    claimedIds.add(id);
    return _quest(claimed: true);
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
}
